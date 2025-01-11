#let contact(text: "", link: none, type: "") = {
  (text: text, link: link, type: type)
}

#let subSection(title: "", titleEnd: none, subTitle: none, subTitleEnd: none, content: []) = {
  (title: title, titleEnd: titleEnd, subTitle: subTitle, subTitleEnd: subTitleEnd, content: content)
}

#let section(title: "", content: subSection()) = {
  (title: title, content: content)
}

#let project(
  theme: rgb("#4273B0"),
  name: "",
  title: none,
  contact: (text: [], link: ""),
  skills: (
    languages: (),
  ),
  main: (title: "", content: []),
  sidebar: (),
  body,
) = {
  let backgroundTitle(content) = heading(
    level: 1,
    numbering: none,
    text(
      fill: theme,
      size: 1.25em,
      weight: "bold",
      [
        #{
          content
        }
        #v(-0.75em)
        #line(length: 100%, stroke: 1pt + theme)
      ],
    ),
  )

  let secondaryTitle(content) = {
    text(weight: "bold", size: 1.125em, content)
  }

  let italicColorTitle(content) = {
    text(style: "italic", size: 1.125em, theme, content)
  }


  let formattedName = stack(
    dir: ltr,
    spacing: 1em,
    text(strong[#name], weight: 100, 4.5em),
    text(strong[Huang], weight: 100, 4.5em, fill: rgb(95%, 55%, 15%, 80%)),
  )

  let formattedTitle = text(strong[#title], weight: 100, 1.5em)

  let titleColumn = align(center)[
    #stack(
      dir: ttb,
      spacing: 1.5em,
      formattedName,
      formattedTitle,
    )
  ]
  let icon(name, shift: 1.5pt) = {
    box(
      baseline: shift,
      height: 10pt,
      image(name + ".svg"),
    )
  }

  let contactColumn = align(left)[#stack(
      dir: ttb,
      spacing: 0.25em,
      ..contact.map(c => {
        if c.link == none [
          #icon(c.type)
          #c.text
        ] else [
          #icon(c.type)
          #underline(link(c.link, text(c.text)))
        ]
      }),
    )]


  grid(
    columns: (2fr, 1fr),
    column-gutter: 1em,
    titleColumn, contactColumn,
  )

  set par(justify: true)

  let parseSubSections(subSections) = {
    stack(
      dir: ttb,
      spacing: 1em,
      ..subSections.map(s => {
        [
          #if s.title != "" {
            box([
              #secondaryTitle(s.title)
              #h(1fr)
              #italicColorTitle(s.titleEnd)
            ])
          }
          #if s.subTitle != none or s.subTitleEnd != none {
            box[
              #text(9pt)[
                #if s.subTitle != none {
                  [#icon("calendar") #s.subTitle]
                }
                #h(1fr)
                #icon("location") #s.subTitleEnd]
            ]
          }
          #s.content
        ]
      }),
    )
  }

  let parseSection(section) = {
    stack(
      dir: ttb,
      spacing: 1em,
      ..section.map(m => {
        if m.title == "" {
          [
            #m.content
          ]
        } else {
          [
            #backgroundTitle(m.title)
            #parseSubSections(m.content)
          ]
        }
      }),
    )
  }

  let mainSection = parseSection(main)
  let sidebarSection = parseSection(sidebar)

  // line(length: 100%, stroke: 1pt + theme)

  grid(
    columns: (2fr, 1fr),
    column-gutter: 1em,
    mainSection, sidebarSection,
  )

  // Main body.
  // set par(justify: true)
  // show: columns.with(3, gutter: 1.3em)

  // body
}

// #import "template.typ": *

#set page(
  margin: (
    left: 10mm,
    right: 10mm,
    top: 15mm,
    bottom: 15mm,
  ),
)

#set text(font: "Mulish")

#show: project.with(
  theme: rgb(95%, 55%, 15%),
  name: "Eric",
  title: "Site Reliability Engineer",
  contact: (
    contact(
      text: "(+886)986366141",
      type: "phone",
    ),
    contact(
      text: "chen-yi-huang",
      link: "https://www.linkedin.com/in/chen-yi-huang/",
      type: "linkedin",
    ),
    contact(
      text: "titaneric",
      link: "https://www.github.com/titaneric",
      type: "github",
    ),
    contact(
      text: "www.titaneric.com",
      link: "https://www.titaneric.com",
      type: "website",
    ),
    contact(
      text: "chenyihuang001@gmail.com",
      link: "mailto:chenyihuang001@gmail.com",
      type: "email",
    ),
  ),
  main: (
    section(
      content: "Certified Kubernetes Administrator, open source enthusiast, and conscientious software engineer with skills in automation, observability, and cloud-native solutions. Possesses strong problem-solving abilities and a keen eye for detail, aiming to improve system reliability, observability, and efficiency.",
    ),
    section(
      title: "Work Experience",
      content: (
        subSection(
          title: "Site Reliability Engineer",
          titleEnd: "Engineering Dept., LINE Taiwan Limited",
          subTitle: "Dec. 2022 – Present",
          subTitleEnd: "Taipei, Taiwan",
          content: list(
            // [Developed golang-based sdk to wrap new internal infra API, designing for easily maintained and client agnostic.
            // ],
            [Co-maintained organization-wide internal Terraform provider #underline(link("https://engineering.linecorp.com/en/blog/terraform-for-verda", "terda")), and promoted Terraform adoption and advocacy at LINE Taiwan.
            ],
            [Optimized log collecting pipelines at LINE Taiwan, and profiled and tuned the self-hosted Loki, reducing storage overhead by *80%* and cutting down required resource by *70%*.
            ],
            [Introduced Grafana Alloy and Faro SDK at LINE Taiwan, achieving end-to-end tracing, RUM, and presented the work at #underline(link("https://coscup.org/2024/en/session/VESN7N", "COSCUP 2024")) .],
            [Designed and developed automation tools such as slack-based workflow automation framework and GitHub Action to improve operational quality.],
            [Designed and built internal infra cost calculator, metrics snapshotter, and dashboards, providing private cloud spending visibility and optimization.],
            // [Developed internal secret management system integration toolkit, including GitHub Action and ArgoCD plugin, to enhance security and compliance.],
            // [Analyzed the root cause of technical debt, and developed alternative solution to resolve it. Also helped sunsetting highly operational cost internal system.],
          ),
        ),
        subSection(
          title: "Senior Engineer",
          titleEnd: "Intelligent Banking Division, E.SUN bank",
          subTitle: "May 2021 – Dec. 2022",
          subTitleEnd: "Taipei, Taiwan",
          content: list(
            [Designed & built up a robust monitoring/alerting system that collect *15+* GB metrics per day across *100+* servers.
            ],
            [
              Experienced in Kubernetes administration & cluster and service migration for *8* cluster (*60+* nodes) with *95%* & *99%* SLA.],
            [Adopted automation tool to construct *production-grade* and *GPU-accelerated* k8s cluster, and contributed to upstream #underline(link("https://github.com/kubernetes-sigs/kubespray", "Kubespray")) & backported to existing playbook. ],
            [ Developed tools for automating process of daily routine, config management, app deployment, and system validation task, which lead to effectively reduce operational costs.],
            // [ Documented thorough k8s installation and operation guide that help pre-trained member leveraing automation tool and deploying a cluster within *1 day*.],
            //  [Assisted colleagues in resolving the issue in Ansible, Linux SysAdmin, and Kubernetes.
            // ]
          ),
        ),
        subSection(
          title: "Engineer",
          titleEnd: "Computer Integration Manufacturer, tsmc",
          subTitle: "Oct 2020 – Jan 2021",
          subTitleEnd: "Hsinchu, Taiwan",
          content: list(),
        ),
      ),
    ),
    section(
      title: "Projects",
      content: (
        subSection(
          title: underline(
            link("https://www.titaneric.com/videos/rust-playground-wasm.mp4", "Rust Playground with WASM"),
          ),
          content: list([Forked #underline(link("https://play.rust-lang.org/?version=stable&mode=debug&edition=2021", "Rust Playground")) to render Web Assembly from compiled Rust, and managed to render them on #underline(link("https://www.titaneric.com/videos/mdbook-wasm.mp4", "mdBook")) as well.]),
        ),
        subSection(
          title: underline(link("/images/courts-reserver-tracing.png", "Court Reserver")),
          content: list(
            [Rust CLI program for Taipei Metropolitan court reservation, runs in the concurrency way to avoid manual operation on APP.],
            // [Captured packets from #underline(link("https://httptoolkit.com/","HTTP Toolkit")) on Android devices, TLS traffic decryption by bypassing certificate pinning, HTTP packets dissection and implemented in Rust, ran in concurrency to avoid manual operation on APP.],
          ),
        ),
        //         subSection(
        //   title: "OCR Helper",
        //   content: list(
        //     [2023 LINE Taiwan Hackthon project, provide RWD web interface for image OCR, summary, and translation.],
        //   ),
        // ),
      ),
    ),
  ),
  sidebar: (
    section(
      title: "Skills",
      content: (
        subSection(
          title: "Programming",
          content: (
            "Python",
            "Golang",
            "Rust",
            // "Typst",
          ).join(" • "),
        ),
        subSection(
          title: "Technologies",
          content: (
            "Kubernetes",
            "Containerization",
            "Nvidia Cloud-Native tech",
            "Linux SysAdmin",
            "TCP/IP",
            "Observability",
            "ArgoCD",
          ).join(" • "),
        ),
        subSection(
          title: "IaC, CI/CD",
          content: (
            "Github Actions",
            "Terraform",
            "Ansible",
          ).join(" • "),
        ),
        // subSection(
        //   title: "Language",
        //   content: (
        //     "Chinese",
        //     "English",
        //   ).join(" • "),
        // ),
      ),
    ),
    section(
      title: "Education",
      content: (
        subSection(
          title: "MEng",
          titleEnd: "Data Science",
          subTitle: "2018 – 2020",
          subTitleEnd: "National Chiao Tung Univ.",
        ),
        subSection(
          title: "BSc",
          titleEnd: "Computer Science",
          subTitle: "2014 – 2018",
          subTitleEnd: "Yuan Ze Univ.",
        ),
      ),
    ),
    section(
      title: "Articles",
      content: (
        subSection(
          content: list(
            underline(
              link(
                "https://www.titaneric.com/grafana-alloy-best-practice/",
                "Grafana Alloy Best Practice",
              ),
            ),
            underline(
              link(
                "https://techblog.lycorp.co.jp/zh-hant/terraform-for-verda",
                "[transl.] Terraform for Verda - A journey of Infrastructure as Code for our private cloud",
              ),
            ),
            underline(
              link(
                "https://www.titaneric.com/the-journey-to-the-kubernetes-networking/",
                "The Journey to the Kubernetes Networking",
              ),
            ),
            underline(
              link(
                "https://www.titaneric.com/the-journey-to-the-kubernetes-metrics/",
                "The Journey to the Kubernetes metrics",
              ),
            ),
            underline(
              link(
                "https://github.com/titaneric/AutoDiff-from-scratch/blob/master/Final\%20Presentation.ipynb",
                "Auto Differentiation",
              ),
            ),
            underline(link("https://www.titaneric.com/buddy-system/", "Buddy System")),
          ),
        ),
      ),
    ),
    section(
      title: "Contributions",
      content: (
        subSection(
          title: "Enhanced VRL functions and Vector's components",
          subTitleEnd: (
            underline(
              link(
                "https://github.com/vectordotdev/vrl/pulls?q=is%3Apr+is%3Amerged+author%3Atitaneric",
                "vectordotdev/vrl",
              ),
            ),
            underline(
              link(
                "https://github.com/vectordotdev/vector/pulls?q=is%3Apr+is%3Amerged+author%3Atitaneric",
                "vectordotdev/vector",
              ),
            ),
          ).join(", "),
        ),
        subSection(
          title: "Reduced redundant calculation in backpropagation",
          subTitleEnd: (
            underline(link("https://github.com/pytorch/pytorch/pull/28651", "pytorch/pytorch")),
            underline(link("https://github.com/jax-ml/jax/issues/1576", "jax-ml/jax")),
          ).join(", "),
        ),
        subSection(
          title: "Fixed Golang's map bucket iteration in eBPF",
          subTitleEnd: underline(link("https://github.com/grafana/beyla/pull/804", "grafana/beyla")),
        ),
        // subSection(
        //   title: "Supported kubeadm patch",
        //   subTitleEnd: underline(link("https://github.com/kubernetes-sigs/kubespray/pull/9326", "kubernetes-sigs/kubespray")),
        // ),
        // subSection(
        //   title: "Bug reporting",
        //   subTitleEnd: underline(link("https://github.com/microsoft/vscode-python/issues/202", "vscode-python")),
        // ),
      ),
    ),
    section(
      title: "Awards & Certs",
      content: (
        subSection(
          content: list(
            "LINE Dev Governance Best Practice",
            // "LINE 2023 Q2 Spot Bonus",
            underline(
              link(
                "https://ti-user-certificates.s3.amazonaws.com/e0df7fbf-a057-42af-8a1f-590912be5460/ca820404-2858-41da-9d18-c3268d010348-huang-chen-yi-80c3b11d-2f72-4183-8271-9743fe40b47d-certificate.pdf",
                "Certified Kubernetes Administrator",
              ),
            ),
            // underline(
            //   link(
            //     "https://github.com/titaneric?achievement=arctic-code-vault-contributor&tab=achievements",
            //     "Arctic Code Vault Contributor",
            //   ),
            // ),
          ),
        ),
      ),
    ),
  ),
)


