+++
title = "Grafana Alloy Best Practice"
date = 2024-08-04

[taxonomies]
categories = ["Learning"]
tags =  ["k8s", "monitoring"]
+++


# TLDR

引進Grafana Alloy及Faro Web SDK，增進RUM以及實現真正的前端到後端的完整tracing。

# 介紹

本文中會針對我在COSCUP 2024上報告的"Grafana Alloy Best Practice: Achieving frontend RUM and E2E tracing"做完整闡述。會介紹Grafana Alloy是甚麼以及它的功能，也提到我是如何引進並設計架構應付可能的巨大telemetry流量需求，提到了中間遇到的挑戰、對應的解決方式、成果及未來展望。在閱讀過程中可以搭配上面的投影片參考。

# 名詞介紹

## Real User Monitoring (RUM)

RUM目的是要從前端網頁使用者或是瀏覽器上蒐集metrics，用以監控前端網的表現，發現潛在的錯誤，也可以用來追蹤使用者的行為(session)。Web vitals是由Google提出的指標，用來衡量用戶在網頁上的體驗，後面介紹的Faro SDK會一併蒐集web vitals，與錯誤及session等RUM相關資訊收進Grafana Alloy中。

## Distributed Tracing

用來描述一段請求在複雜且分散式系統中的完整流程，可以用來增進應用的可視性，除了可以知道請求在各個元件的消耗時間之外，也可以用來分析錯誤的發生原因。主流已經採用OpenTelemetry標準，它除了trace之外，也有針對log, metrics, profiling, core dump定義相關標準。

## Grafana Alloy

Grafana Alloy是高效能，且有彈性的一種OpenTelemetry Collector。可以支援metrics, log以及trace等資料，也提供pipeline的方式，使用語法叫做alloy類似於Terraform HCL，用來描述這些資料該如何被處理，並且送進最終的目的端。在這篇文章中主要使用`faro.receiver`元件接受來自Faro Web SDK的資料。

註：相較於原始opentelemetry collector使用YAML定義資料流，我覺得alloy使用上比較直覺，也確實如官網所描述的，比較方便debug。

## Grafana Faro Web SDK

Grafana Faro是JS的library，可以引用在前端的應用中，用來蒐集前述的RUM及基本的metadata例如瀏覽器及OS名稱。也與opentelemetry-js整合，針對前端應用`fetch`及`XML`請求，會自動量測請求的trace。它也能將console log、error、event及[performance resource timing](https://developer.mozilla.org/en-US/docs/Web/API/PerformanceResourceTiming)一起送進Grafana Alloy的Faro receiver中。

# 現有架構

目前已經引進Grafana Alloy及Faro SDK進目前任職公司，在引進時需要考慮現有的架構，並思考如何整合。下面針對現有架構作介紹。

## 技術堆疊

在基本的infra上，底層是由OpenStack建立的私有雲架構，上層提供了Kubernetes、Load Balancer、Object Storage、Redis及MySQL等服務，這些infra主要由日本及韓國負責維運。

在這架構上，台灣的SRE在Kubernetes上部署了Traefik或Contour Ingress Controller，再上層的服務包含Tempo, Loki, ArgoCD, Grafana。

{{ pdf(source="//www.slideshare.net/slideshow/embed_code/key/gxSQKJ88aLrpQS", start=18)}}

## 應用團隊監控架構

應用團隊的服務也是部署在k8s上，前面的流量經過Load Balancer進來之後進到Traefik部署的那些節點上，Traefik聆聽Ingress或是IngressRoute設定的規則將流量送進服務內。

這些應用服務會產生log, metrics及trace。metrics抓取規則主要是由PodMonitor或者ServiceMonitor定義，收進cluster上的Agent mode的Prometheus(Statefulset部署)上，會進一步透過remote write機制送進其他團隊管理的Prometheus存放。

log主要會將stdout及stderr寫到節點上的log file上存放，我們使用promtail(Daemonset部暑)將這些log做前處理(加入敏感資料mask及k8s attributes等)之後，會直接送進SRE管理的Loki裡。

trace會先拋到cluster上的otel collector(Deployment部暑)上，一樣會先做些前處理(memory限制，限制每一個span的attributes數量等)，因為數量比較大我們選擇先拋到Kafka topic上，之後會在SRE cluster進行處理。

{{ pdf(source="//www.slideshare.net/slideshow/embed_code/key/gxSQKJ88aLrpQS", start=19)}}

## SRE監控架構

同樣在SRE cluster會部署Traefik負責接受監控的流量，上面如技術堆疊中提到的部署ArgoCD、Grafana、Tempo、Loki等服務。Grafana的資料來源主要是其他團隊管理的Prometheus，本地的Tempo及Loki，滿足metrics、log及trace的視覺化及告警需求。

在metrics部分，我們僅是使用Prometheus remote read功能讀取其他團隊的遠端Prometheus；在logs部分，透過Loki push API打進來的logs都會被Loki cluster消化，並存放到兼容S3 API的Object Storage中；SRE cluster上會另外部署一套otel collector，負責consume來自Kafka topic的trace，之後送進Tempo cluster進一步消化，也存在Object Storage中，

{{ pdf(source="//www.slideshare.net/slideshow/embed_code/key/gxSQKJ88aLrpQS", start=20)}}

# 如何設計Alloy

## 需求

在設計之前有一些基本的條件需要滿足

*必要*

- 充分利用並整合現有的監控平台
- 自動化且方便地部暑Alloy
- 因為Alloy會直接接收來自使用者最真實的流量，所以必須有基本的管控措施。

*非必要但有會更好*

- 提供簡單的流程給應用團隊申請使用
- 提供範例程式串接Faro SDK，包含server-side rendering及client-side rendering

在申請流程方面，使用者目前能透過Slack workflow申請Alloy使用，會觸發一系列的自動化，使用者就能直接使用。我們也提供Nextjs的範例程式，也寫了教學文件，供前端應用的開發者能輕鬆地串接Faro SDK。接著會針對*必要*需求，設計Alloy的自動化以及Gateway架構。

## 應用團隊端的Alloy架構

Alloy(Deployment部暑)本身是透過ArgoCD ApplicationSet方式部暑，我們抽離了各種跟應用團隊相關的設定成變數，在動態生成ArgoCD Application時能透過go template方式將各項設定填入Alloy的config，這些變數包含了cluster、團隊及namespace名稱等。

Alloy收進來的log是直接透過`loki.write`直接拋到SRE掌管的Loki cluster上；trace則是送到cluster上的otel collector，如前述說明的會將trace拋到Kafka上，之後會進到Tempo存放。

Alloy會開啟`faro.receiver`元件功能，在Alloy Deployment前面會掛一個k8s Service，不同於一般的ClusterIP，我們選擇LoadBalancer type，底層的controller聆聽到之後會自動在cluster前面再創建一個LoadBalancer，基本上這樣就可以供應用程式使用。不過Faro SDK蒐集到的telemetry資料並不是直接進入這個LB，前面會再經過一個gateway。

{{ pdf(source="//www.slideshare.net/slideshow/embed_code/key/gxSQKJ88aLrpQS", start=23)}}

## SRE端Alloy Gateway架構

為了能更方便的掌握各個團隊的telemetry流量，我們選擇在SRE的cluster上部暑Contour當作gateway，Contour的data plane是超高效能的Envoy，也提供了rate limit，如果必要我們可以針對某一些團隊的流量進行限流避免影響到gateway本身，以及對應用團隊cluster的衝擊。

我們使用了Contour提供的HTTPProxy，將相同domain但不同path的請求，送到應用團隊cluster的Alloy入口LB。也用了Endpoint及Service將Alloy入口LB的IP作為k8s service的封裝。

{{ pdf(source="//www.slideshare.net/slideshow/embed_code/key/gxSQKJ88aLrpQS", start=23)}}

## 設計緣由

Q: 為什麼使用統一的Alloy gateway，而不是每一個cluster有自己的ingress將流量送進Alloy?

A: 首先我們想要確實的掌握telemetry流量，有了gateway方便我們做監控，如果需要也可以充分利用Contour提供的rate limit功能。再來，我們想要區別一般應用及telemetry的流量，不希望telemetry流量衝擊到一般使用者使用。再者，如果要在每一個應用cluster的ingress進入流量，考量到不同的流量需要分開，就必須創建新的node，部暑新的Traefik，設定LB及DNS record，這需要應用團隊協助進行，這大大的增加佈署上的不便。最後，按照公司的規範，對外的服務需要經過Security Review，如果採用Alloy gateway，只要跑過一次就好，應用團隊也就不用每一個cluster都需要跑這個流程。

Q：為何選擇Contour當作Ingress Controller，而不用Traefik或者其他？

A：我們先前已經有使用過Contour的使用經驗，我們觀察到Contour以及Envoy的效能非常好，需要的記憶體與Traefik相比也少非常多。我們曾經考慮過Envoy自己出的Envoy Gateway，但可惜我們的k8s版本不太相符。也為了不要造成引入後帶來的維護及技術堆疊上的分歧。

## 挑戰

因為Alloy會直接接收來自真實使用者的流量，不用經過CDN等其他cache機制，所以為了能應付潛在的巨大流量，我們針對Contour以及Alloy做了壓力測試，發現他們的效能以及表現都非常好。在流量控制上，我們有3層保護關卡：第一個是應用程式可以設定sample rate，決定多少比率的流量應該被送到Alloy gateway；第二個是使用Contour的rate limit功能，可以針對特定用戶或者全局的設定流量上限；最後一個是Alloy的`faro.receiver`也提供了rate limit功能，超過上限會回429。理想上這樣的層層保護設計可以保護SRE以及應用團隊的cluster。

Faro SDK蒐集到的資料最終會被送進Loki及Tempo中，我們為了因應潛在的巨大流量，也需要特別針對Loki及Tempo做性能調校，現有的監控平台是multi-tenant的設計，如果需要也可以針對不同的tenant設定rate limit。

Alloy將除了trace之外的資料全部透過log寫入Loki，這也包含了web vitals以及performance resource timing的數值型的資料，這雖然解決了Prometheus可能的high-cardinality問題，但這在資料視覺化上不太方便呈現。官方提供的Faro SDK dashboard是使用logql去拿到Loki的資料，當選取的時段一長，可能就會遇到載入過久的問題，在使用上少了各項metadata，所以呈現的數值都是粗糙的，沒有更為細緻的數據呈現。我們使用Loki ruler將常見的logql語法及metadata，轉化成Prometheus metrics，因為metadata也變成了metrics label之一，這樣就可以解決上述的問題，也能看到比如第118版應用程式在Mac的Arc瀏覽器的web vitals數值，供前端開發者效能優化的參考。

Faro SDK預設的trace propagation格式是使用W3C Trace Context，但是我們在應用團隊cluster佈署的Traefik僅支援Jaeger格式，如果要達成真正的前端到後端完整的tracing，一致的trace propagation是必要的，因為Traefik相對前端或後端應用不方便升級，所以造成前端或後端的應用需要配合Traefik的propagation格式，才能看到完整的tracing軌跡。應用團隊不僅會呼叫自己的服務，也可能呼叫第三方的API，這時如果第三方的API gateway將trace相關的HTTP Header（`TraceParent`或`Uber-Trace-Id`）移除，在那之後的tracing將不會被完整串接起來，我們在導入之後也發生這個狀況，在通知第三方服務不要過濾掉這些HTTP Header之後解決了這個issue。

# 成果及展望

## 成果

目前團隊的telemetry資料會經過Loki ruler轉換成Prometheus metrics。應用團隊可以根據不同的metadata，例如app名稱、版本、環境、瀏覽器及OS版本的，看到不同的web vitals變化。同時也參考了Grafana Cloud，設計了session的dashboard，應用團隊可以看到不同的用戶在不同session的操作，了解用戶的使用行為。

## 未來工作

如前面提到的，Traefik受限的trace propagation格式造成了開發者的困擾，在Traefik v3之後統一使用OpenTelemetry及W3C Trace Context標準，我們預計將逐步升級上去。

在台灣這邊，應用團隊不管透過手動寫入或是library協助自動產生instrumentation都有累積一段經驗，但是採用的團隊仍不夠廣泛，而且應用團隊仍會需要手動在應用程式注入片段的程式碼才能發揮tracing功能，之後會研究zero-code instrumentation，例如Grafana Beyla這樣的工具，利用eBPF技術在底層追蹤請求及回覆，並轉換成trace。如此一來，團隊能更加專注開發應用，不須費盡心思撰寫instrumentation相關程式，也能享受tracing或其他監控帶來的好處。

# 完整投影片

{{ pdf(source="//www.slideshare.net/slideshow/embed_code/key/gxSQKJ88aLrpQS")}}

