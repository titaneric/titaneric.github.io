#import "template.typ": *

#set page(
  margin: (
    left: 10mm,
    right: 10mm,
    top: 15mm,
    bottom: 15mm,
  ),
)

// #set text(font: "Mulish")

#show: project.with(
  theme: rgb(95%, 55%, 15%),
  name: "Eric",
  title: "Senior Site Reliability Engineer",
  contact: (
    // Uncomment to include phone number:
    // contact(
    //   text: "(+886) 986-366-141",
    //   type: "phone",
    // ),
    contact(
      text: "Chen-Yi Huang",
      link: "https://www.linkedin.com/in/chen-yi-huang/",
      type: "linkedin",
    ),
    contact(
      text: "github.com/titaneric",
      link: "https://www.github.com/titaneric",
      type: "github",
    ),
    contact(
      text: "titaneric.com",
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
      content: underline(link("https://ti-user-certificates.s3.amazonaws.com/e0df7fbf-a057-42af-8a1f-590912be5460/ca820404-2858-41da-9d18-c3268d010348-huang-chen-yi-80c3b11d-2f72-4183-8271-9743fe40b47d-certificate.pdf", "Certified Kubernetes Administrator")) + ", open-source enthusiast, and detail-oriented software engineer with expertise in automation, observability, and cloud-native solutions. Skilled in problem-solving and system optimization, aiming to enhance reliability, efficiency, and scalability.",
    ),
    section(
      title: "Work Experience",
      content: (
        subSection(
          title: "Site Reliability Engineer",
          titleEnd: "Engineering Dept., LINE Taiwan Limited",
          subTitle: "Dec 2022 – Present",
          subTitleEnd: "Taipei, Taiwan",
          content: list(
            [#underline(link("https://techblog.lycorp.co.jp/zh-hant/grafana-loki-upgrade-1", "Optimized log collection pipelines at LINE Taiwan and upgraded the self-hosted Loki")), *achieving a 3x increase in log ingestion and query performance (P99 under 10s), while eliminating object storage overhead and reducing costs by 70%*.
            ],
            [Co-maintained the organization-wide #underline(link("https://engineering.linecorp.com/en/blog/terraform-for-verda", "internal Terraform provider Terda")), and actively promoted Terraform adoption and advocacy within LINE Taiwan.
            ],
            [Introduced Grafana Alloy and Faro SDK at LINE Taiwan, enabling end-to-end tracing and real user monitoring. Presented this work at #underline(link("https://coscup.org/2024/en/session/VESN7N", "COSCUP 2024")).
            ],
            [Developed a Go-based SDK to wrap the successor infrastructure API post-LY merger, ensuring maintainability and client-agnostic design.
            ],
            [Created automation tools, including a Slack workflow automation framework and GitHub Actions, to improve operational efficiency and quality.
            ],
            [Designed and implemented an internal infrastructure cost calculator, metrics snapshotter, and dashboards, providing visibility into private cloud spending and enabling cost optimization.
            ],
          ),
        ),
        subSection(
          title: "Senior Engineer",
          titleEnd: "Intelligent Banking Division, E.SUN Bank",
          subTitle: "May 2021 – Dec 2022",
          subTitleEnd: "Taipei, Taiwan",
          content: list(
            [Designed and built a robust monitoring/alerting system that collected *15+ GB* of metrics daily across *100+ servers*.
            ],
            [Managed Kubernetes administration and migration for *8 clusters* (*60+ nodes*) with *95%* and *99%* SLA.
            ],
            [Adopted automation tools to construct *production-grade* and *GPU-accelerated* Kubernetes clusters, contributing to upstream #underline(link("https://github.com/kubernetes-sigs/kubespray", "Kubespray")) and backporting to existing playbooks.
            ],
            [Developed tools to automate daily routines, configuration management, application deployment, and system validation tasks, significantly reducing operational costs.
            ],
          ),
        ),
      ),
    ),
    section(
      title: "Projects",
      content: (
        subSection(
          title: underline(link("https://www.titaneric.com/videos/rust-playground-wasm.mp4", "Rust Playground with WASM")),
          content: list(
            [Forked #underline(link("https://play.rust-lang.org/?version=stable&mode=debug&edition=2021", "Rust Playground")) to render WebAssembly from compiled Rust code in the browser and integrated it into #underline(link("https://www.titaneric.com/videos/mdbook-wasm.mp4", "mdBook")).
            ],
          ),
        ),
        subSection(
          title: underline(link("https://www.titaneric.com/images/courts-reserver-tracing.png", "Court Reserver")),
          content: list(
            [Developed a Rust CLI program for Taipei Metropolitan court reservations, enabling concurrent reservations to avoid manual operations on browsers or apps.
            ],
          ),
        ),
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
            "Go",
            "Rust",
          ).join(" • "),
        ),
        subSection(
          title: "Technologies",
          content: (
            "Kubernetes",
            "Containerization",
            "Nvidia Cloud-Native Tech",
            "Linux SysAdmin",
            "TCP/IP",
            "Observability",
            "ArgoCD",
          ).join(" • "),
        ),
        subSection(
          title: "IaC, CI/CD",
          content: (
            "GitHub Actions",
            "Terraform",
            "Ansible",
          ).join(" • "),
        ),
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
                "https://techblog.lycorp.co.jp/zh-hant/grafana-alloy-best-practice",
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
                "https://www.titaneric.com/posts/the-journey-to-the-kubernetes-networking/",
                "The Journey to the Kubernetes Networking",
              ),
            ),
            underline(
              link(
                "https://www.titaneric.com/posts/the-journey-to-the-kubernetes-metrics/",
                "The Journey to the Kubernetes metrics",
              ),
            ),
            // underline(
            //   link(
            //     "https://github.com/titaneric/AutoDiff-from-scratch/blob/master/Final\%20Presentation.ipynb",
            //     "Auto Differentiation",
            //   ),
            // ),
            underline(link("https://www.titaneric.com/posts/buddy-system/", "Buddy System")),
            underline(link("https://www.titaneric.com/archive/", "More...")),
          ),
        ),
      ),
    ),
    section(
      title: "Contributions",
      content: (
        subSection(
          title: "Enhanced VRL Functions and Vector Components",
          subTitleEnd: (
            underline(link("https://github.com/vectordotdev/vrl/pulls?q=is%3Apr+is%3Amerged+author%3Atitaneric", "vectordotdev/vrl")),
            underline(link("https://github.com/vectordotdev/vector/pulls?q=is%3Apr+is%3Amerged+author%3Atitaneric", "vectordotdev/vector")),
          ).join(", "),
        ),
        subSection(
          title: "Reduced Redundant Calculations in Backpropagation",
          subTitleEnd: (
            underline(link("https://github.com/pytorch/pytorch/pull/28651", "pytorch/pytorch")),
            underline(link("https://github.com/jax-ml/jax/issues/1576", "jax-ml/jax")),
          ).join(", "),
        ),
        subSection(
          title: "Fixed Low-Level Golang Map Traversal in eBPF",
          subTitleEnd: underline(link("https://github.com/grafana/beyla/pull/804", "grafana/beyla")),
        ),
      ),
    ),
    // section(
    //   title: "Awards & Certifications",
    //   content: (
    //     subSection(
    //       content: list(
    //         "LINE Dev Governance Best Practice",
    //         underline(link("https://ti-user-certificates.s3.amazonaws.com/e0df7fbf-a057-42af-8a1f-590912be5460/ca820404-2858-41da-9d18-c3268d010348-huang-chen-yi-80c3b11d-2f72-4183-8271-9743fe40b47d-certificate.pdf", "Certified Kubernetes Administrator")),
    //       ),
    //     ),
    //   ),
    // ),
  ),
)