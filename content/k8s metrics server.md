+++
title = "Kubernetes metrics-server"
date = 2021-10-10

[taxonomies]
categories = ["Notes"]
tags = ["k8s", "deep dive"]

[extra]
comments = true
+++

# 背景

**metrics-server**是kubernetes用來量測cluster中node以及pod中的CPU以及記憶體使用率的工具，這些被量測到的資訊會被kubectl top以及HPA controller收集，分別做為查看目前k8s系統狀態以及擴充服務的依據。

metrics-server本身也如同k8s的絕大多數物件一樣，它是以web service的形式存在k8s當中，原始碼在[kubernetes-sigs/metrics-server](https://github.com/kubernetes-sigs/metrics-server)，本篇文章要來解析metrics-server中entry point、所使用的metrics基本物件、metrics如何被收集以及何時會被更新。

# Dive in

## Entry point

metrics-server在build過後，是用Docker image的形式將服務包裝成在k8s中運行的container。在原始碼當中的根目錄中，Dockerfile先是執行`make metrics-server`將metrics-server build成binary file，最後在entrypoint運行`cmd/metrics-server`。

```Dockerfile
...
WORKDIR /go/src/sigs.k8s.io/metrics-server
COPY go.mod .
COPY go.sum .
RUN go mod download

COPY pkg pkg
COPY cmd cmd
COPY Makefile Makefile
...
RUN make metrics-server
...
ENTRYPOINT ["/metrics-server"]
```

```Makefile
metrics-server: $(SRC_DEPS)
	GOARCH=$(ARCH) CGO_ENABLED=0 go build -ldflags "$(LDFLAGS)" -o metrics-server sigs.k8s.io/metrics-server/cmd/metrics-server
```

在上面Makefile可以看到，go build的來源是metrics-server下的`cmd/metrics-server`，該目錄下的metrics-server.go執行在`cmd/metrics-server/app`中定義的cobra指令。

```go
import (
	...
	"sigs.k8s.io/metrics-server/cmd/metrics-server/app"
)
func main() {
	...
	cmd := app.NewMetricsServerCommand(genericapiserver.SetupSignalHandler())
	cmd.Flags().AddGoFlagSet(flag.CommandLine)
	if err := cmd.Execute(); err != nil {
		panic(err)
	}
}
```

在`cmd/metrics-server/app/metrics-server.go`中的`NewMetricsServerCommand()`function用到`cmd/metrics-server/app/options/options.go`中定義的`NewOptions()` function。定義metrics-server需要用到的設定`Options` struct，該設定會傳給`runCommand()` function最後透過cobra的`Execute()` method執行。

```go
import (
	...
	"sigs.k8s.io/metrics-server/cmd/metrics-server/app/options"
)
// NewMetricsServerCommand provides a CLI handler for the metrics server entrypoint
func NewMetricsServerCommand(stopCh <-chan struct{}) *cobra.Command {
	opts := options.NewOptions()

	cmd := &cobra.Command{
		Short: "Launch metrics-server",
		Long:  "Launch metrics-server",
		RunE: func(c *cobra.Command, args []string) error {
			if err := runCommand(opts, stopCh); err != nil {
				return err
			}
			return nil
		},
	}
	...
	return cmd
}
```
下面的ServerConfig method回傳定義在`pkg/server`中定義的`Config` struct，會被當作web service需要的參數最後在`Complete()` method中回傳`Server` struct，即是metrics-server自身的web server，一直執行該server直到收到stop signal為止，這樣程式的進入點就結束了，接著細部看各項server設定以及metrics用到的struct。
```go
func runCommand(o *options.Options, stopCh <-chan struct{}) error {
	...
	config, err := o.ServerConfig()
	...
	s, err := config.Complete()
	...
	return s.RunUntil(stopCh)
}
```

## metrics基本物件

### Server參數

前面有提過`NewOptions()` function會回傳`Options` struct，裡面有`MetricResolution`，該項目定義了metrics-server多久抓一次在node及pod中的metrics，預設是60秒抓一次。
```go
func NewOptions() *Options {
	return &Options{
		...
		KubeletClient:  NewKubeletClientOptions(),

		MetricResolution: 60 * time.Second,
	}
}
```
```go
type Options struct {
	...
	KubeletClient  *KubeletClientOptions

	MetricResolution time.Duration
	...
}
```
在`runCommand()`function中會使用`ServerConfig()`method建立Config，`MetricResolution`即是剛才在Options中定義的，`ScrapeTimeout`是抓取後隔多久會發生timeout的情形，預設是`MetricResolution`*0.9。
```go
func (o Options) ServerConfig() (*server.Config, error) {
	...
	return &server.Config{
		...
		MetricResolution: o.MetricResolution,
		ScrapeTimeout:    time.Duration(float64(o.MetricResolution) * 0.90), // scrape timeout is 90% of the scrape interval
	}, nil
}
```
```go
type Config struct {
	Apiserver        *genericapiserver.Config
	Rest             *rest.Config
	Kubelet          *client.KubeletClientConfig
	MetricResolution time.Duration
	ScrapeTimeout    time.Duration
}
```


### metrics抓取物件

`scraper`是真正向node以及pods抓取metrics的必要物件，裡面有一項是實現了`KubeletMetricsInterface`的`kubeletClient`，另外的`scrapeTimeout`即是前面`Config` struct的`ScrapeTimeout`，scraper會每隔`scrapeTimeout`定時透過`kubeletClient`跟kubelet要資料。

```go
type scraper struct {
	nodeLister    v1listers.NodeLister
	kubeletClient client.KubeletMetricsInterface
	scrapeTimeout time.Duration
}
```

`MetricsBatch`是scraper抓到metrics後回傳的物V，包含了針對node以及pod的metrics，`Nodes`是node名稱映到MetricsPoint的map；`Pods`是namespace映到container名稱再映到MetricsPoint的map。MetricsPoint包含`CumulativeCpuUsed`及`MemoryUsage`兩個CPU以及Memory的使用率。
```go
// MetricsBaVch is a single batch of pod, container, and node metrics from some source.
type MetricsBatch struct {
	Nodes map[string]MetricsPoint
	Pods  map[apitypes.NamespacedName]PodMetricsPoint
}
```

```go
// PodMetricsPoint contains the metrics for some pod's containers.
type PodMetricsPoint struct {
	Containers map[string]MetricsPoint
}

// MetricsPoint represents the a set of specific metrics at some point in time.
type MetricsPoint struct {
	...
	Timestamp time.Time
	// CumulativeCpuUsed is the cumulative cpu used at Timestamp from the StartTime of container/node. Unit: nano core * seconds.
	CumulativeCpuUsed uint64
	// MemoryUsage is the working set size. Unit: bytes.
	MemoryUsage uint64
}
```
### metrics存放物件

`storage`存放的是前面`scraper`收集而來的metrics，並有個別分`podStorage`以及`nodeStorage`。

```go
// nodeStorage is a thread save nodeStorage for node and pod metrics.
type storage struct {
	mu    sync.RWMutex
	pods  podStorage
	nodes nodeStorage
}
```

從下面的`podStorage`以及`nodeStorage`可以注意到這兩個struct都有存放last以及prev兩個metrics，即是現在的metrics內容以及上次抓到的metrics內容，之後會根據兩者metrics差異計算資源的使用率。
```go
type podStorage struct {
	// last stores pod metric points from last scrape
	last map[apitypes.NamespacedName]PodMetricsPoint
	// prev sVores pod metric points from scrape preceding the last one.
	// Points timestamp should proceed the corresponding points from last and have same start time (no restart between them).
	prev map[apitypes.NamespacedName]PodMetricsPoint
	// scrape period of metrics server
	metricResolution time.Duration
}
```

```go
type nodeStorage struct {
	// last stores node metric points from last scrape
	last map[string]MetricsPoint
	// prev stores node metric points from scrape preceding the last one.
	// Points timestamp should proceed the corresponding points from last.
	prev map[string]MetricsPoint
}
```


## metrics收集

同樣在`runCommand`中的，取得`Config` instance之後，會呼叫`Complete` method建立`Server` instance。其中有兩個很重要的物件，一個是名為`scrape`的`scraper` instance，主要負責進行node及pod metrics的抓取，所以要將`ScrapeTimeout`傳給它；另外一個是`storage` instance，就跟它的名字一樣主要負責存放抓下來的metrics。

另外要注意的是，`kubeletClient`也會被建立出來傳給`scrape`，真正拿metrics是透過這個client去跟kubelet拿，會在之後做說明。
```go
func (c Config) Complete() (*server, error) {
	kubeletClient, err := resource.NewClient(*c.Kubelet)
	...
	nodes := informer.Core().V1().Nodes()
	scrape := scraper.NewScraper(nodes.Lister(), kubeletClient, c.ScrapeTimeout)

	...
	store := storage.NewStorage(c.MetricResolution)

	s := NewServer(
		...
		store,
		scrape,
		c.MetricResolution,
	)
	...
	return s, nil
}
```
在建立完`Server` instance之後，最終會執行`RunUntil` method，它會起一個go routine執行`runScrape` method進行metrics的抓取及存放。
```go
// RunUntil starts background scraping goroutine and runs apiserver serving metrics.
func (s *server) RunUntil(stopCh <-chan struct{}) error {
	...
	// Start serving API and scrape loop
	go s.runScrape(ctx)
	...
}
```
`runScrape` method會利用`NewTicker`建立一個ticker，當中包含一個channel，每隔`resolution`時間後，ticker會敲一次並把時間傳給channel。之後會進行無窮迴圈，從channel中取得當前時間，並呼叫`tick` method執行核心的metrics抓取。
```go
func (s *server) runScrape(ctx context.Context) {
	ticker := time.NewTicker(s.resolution)
	defer ticker.Stop()
	s.tick(ctx, time.Now())

	for {
		select {
		case startTime := <-ticker.C:
			s.tick(ctx, startTime)
		case <-ctx.Done():
			return
		}
	}
}
```
剛才在`Complete` method中定義的scraper以及storage instance就是在這裡會被呼叫到。scraper會呼叫`Scrape` method抓取metrics，回傳的metrics內容是`MetricsBatch` instance。
```go
func (s *server) tick(ctx context.Context, startTime time.Time) {
	...
	klog.V(6).InfoS("Scraping metrics")
	data := s.scraper.Scrape(ctx)

	klog.V(6).InfoS("Storing metrics")
	s.storage.Store(data)
	...
}
```

scraper的`Scraper` method會對node以及pod進行metrics的抓取，首先列出所有的nodes之後，建立一個大小為nodes數量的`responseChannel`存放收集而來的metrics。之後針對nodes中個別的node起一個go routine，並呼叫`collectNode` method，針對node拿對應的metrics，非同步地將回傳結果放入剛才建立的`responseChannel`。
```go
func (c *scraper) Scrape(baseCtx context.C:ntext) *storage.MetricsBatch {
	nodes, err := c.nodeLister.List(labels.Everything())
	...
	klog.V(1).InfoS("Scraping metrics from nodes", "nodeCount", len(nodes))

	responseChannel := make(chan *storage.MetricsBatch, len(nodes))
	defer close(responseChannel)


	for _, node := range nodes {
		go func(node *corev1.Node) {
			...
			klog.V(2).InfoS("Scraping node", "node", klog.KObj(node))
			m, err := c.collectNode(ctx, node)
			...
			responseChannel <- m
		}(node)
	}
	...
}
```
`collectNode` method會透過剛在`Complete` method中建立的`kubeletClient`跟kubelet拿node的metrics。`kubeletClient`實現了`KubeletMetricsInterface`，並透過RESTful API去跟kubelet拿metrics。kubelet如何實現這部分有點超出本文範圍等之後再來trace。
```go
func (c *scraper) collectNode(ctx context.Context, node *corev1.Node) (*storage.MetricsBatch, error) {
	...
	ms, err := c.kubeletClient.GetMetrics(ctx, node)
	...
	return ms, nil
}
```
```go
// KubeletMetricsInterface knows how to fetch metrics from the Kubelet
type KubeletMetricsInterface interface {
	// GetMetrics fetches Resource metrics from the given Kubelet
	GetMetrics(ctx context.Context, node *v1.Node) (*storage.MetricsBatch, error)
}
```
```go
//GetMetrics get metrics from kubelet /metrics/resource endpoint
func (kc *kubeletClient) GetMetrics(ctx context.Context, node *corev1.Node) (*storage.MetricsBatch, error) {
	port := kc.defaultPort
	...
	addr, err := kc.addrResolver.NodeAddress(node)
	if err != nil {
		return nil, err
	}
	url := url.URL{
		Scheme: kc.scheme,
		Host:   net.JoinHostPort(addr, strconv.Itoa(port)),
		Path:   "/metrics/resource",
	}

	req, err := http.NewRequest("GET", url.String(), nil)
	...
}
```

## metrics儲放

接下來要看存放metrics的`Store` method，這裡會針對nodes以及pods個別呼叫`Store` method。同時也會更新物件中的last以及prev內容。

```go
func (s *storage) Store(batch *MetricsBatch) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.nodes.Store(batch)
	s.pods.Store(batch)
}
```

```go
func (s *nodeStorage) Store(batch *MetricsBatch) {
	lastNodes := make(map[string]MetricsPoint, len(batch.Nodes))
	prevNodes := make(map[string]MetricsPoint, len(batch.Nodes))
	for nodeName, newPoint := range batch.Nodes {
		if _, exists := lastNodes[nodeName]; exists {
			klog.ErrorS(nil, "Got duplicate node point", "node", klog.KRef("", nodeName))
			continue
		}
		lastNodes[nodeName] = newPoint
		...
	}
	s.last = lastNodes
	s.prev = prevNodes

	// Only count last for which metrics can be returned.
	pointsStored.WithLabelValues("node").Set(float64(len(prevNodes)))
}
```

```go
func (s *podStorage) Store(newPods *MetricsBatch) {
	lastPods := make(map[apitypes.NamespacedName]PodMetricsPoint, len(newPods.Pods))
	prevPods := make(map[apitypes.NamespacedName]PodMetricsPoint, len(newPods.Pods))
	var containerCount int
	for podRef, newPod := range newPods.Pods {
		...
		for containerName, newPoint := range newPod.Containers {
			...
			newLastPod.Containers[containerName] = newPoint
			...
		}
		containerPoints := len(newPrevPod.Containers)
		if containerPoints > 0 {
			prevPods[podRef] = newPrevPod
		}
		lastPods[podRef] = newLastPod

		// Only count containers for which metrics can be returned.
		containerCount += containerPoints
	}
	s.last = lastPods
	s.prev = prevPods

	pointsStored.WithLabelValues("container").Set(float64(containerCount))
}
```

# 結語

本篇文章trace了metrics-server的進入點、如何抓取nodes及pods的metrics以及如何存放剛抓到的metrics。metrics-server每隔一段時間就會抓取metrics，並存放到內部定義的資料結構中。其實`podStorage`以及`nodeStorage`還有一個method是`GetMetrics`，這之後會被kubectl top以及HPA controller呼叫到，該method會從這些資料結構中抓取metrics以及計算metrics差異，這會在之後的文章做說明。