import urllib3
import os

urllib3.disable_warnings()
import requests
from bs4 import BeautifulSoup
import shutil
from playwright.sync_api import sync_playwright


account = os.environ.get("ACCOUNT")
password = os.environ.get("PASSWORD")
doc_id = os.environ.get("DOCID")
project_id = os.environ.get("PROJID")
WAIT_TIMEOUT = float(os.environ.get("TIMEOUT"))
csrf_token_selector = "ol-csrfToken"
account_input = "#email"
password_input = "#password"
submit_btn = (
    "#main-content > div.card.login-register-card > form > div.actions > button"
)
download_pdf_btn = "#ide-body > div.ui-layout-center.ui-layout-pane.ui-layout-pane-center > div.full-size.ui-layout-container > div.ui-layout-east.ui-layout-pane.ui-layout-pane-east > div > pdf-preview > div.pdf.full-size > div.toolbar.toolbar-pdf.toolbar-pdf-hybrid.btn-toolbar > div.toolbar-pdf-left > a > i"
project_url = "https://www.overleaf.com/project"

login_url = "https://www.overleaf.com/login"

page_url = "https://www.overleaf.com/project/{}".format(project_id)
compile_url = "https://www.overleaf.com/project/{}/compile".format(project_id)
print(page_url)
print(compile_url)
print(account)


def get_csrf_token(page_text):
    soup = BeautifulSoup(page_text, "html.parser")
    csrf_ele = soup.find("meta", {"name": csrf_token_selector})
    csrf_token = csrf_ele["content"]
    return csrf_token


def download_resume(compile_response, cookie):
    response = compile_response

    if response.status_code == 200:
        res_json = response.json()
        download_domain = res_json["pdfDownloadDomain"]
        compile_group = res_json["compileGroup"]
        clsi_server_id = res_json["clsiServerId"]
        pdf_url = next(
            iter(
                [
                    output["url"]
                    for output in res_json["outputFiles"]
                    if output["type"] == "pdf"
                ]
            )
        )
        # print(download_domain, pdf_url, compile_group, clsi_server_id)

        download_pdf_url = "{}{}".format(download_domain, pdf_url)
        params = {
            "compileGroup": compile_group,
            "clsiserverid": clsi_server_id,
        }
        pdf_headers = {
            "Accept": "application/pdf",
        }
        with requests.get(
            url=download_pdf_url,
            headers=pdf_headers,
            params=params,
            verify=False,
            stream=True,
        ) as response:
            if response.status_code == 200:
                with open("resume.pdf", "wb") as f:
                    shutil.copyfileobj(response.raw, f)
                print("the resume has been downloaded")
    else:
        # print(response.text)
        print("failed to download the resume pdf")


def compile(csrf_token, cookie):
    import requests

    headers = {
        "authority": "www.overleaf.com",
        "sec-ch-ua": '" Not A;Brand";v="99", "Chromium";v="98", "Microsoft Edge";v="98"',
        "accept": "application/json",
        "x-csrf-token": csrf_token,
        "sec-ch-ua-mobile": "?0",
        "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36 Edg/98.0.1108.56",
        "sec-ch-ua-platform": '"Windows"',
        "origin": "https://www.overleaf.com",
        "sec-fetch-site": "same-origin",
        "sec-fetch-mode": "cors",
        "sec-fetch-dest": "empty",
        "referer": page_url,
        "accept-language": "en-US,en;q=0.9,zh-TW;q=0.8,zh;q=0.7",
    }

    params = (("auto_compile", "true"),)

    json_data = {
        "rootDoc_id": doc_id,
        "draft": False,
        "check": "silent",
        "incrementalCompilesEnabled": True,
    }

    response = requests.post(
        compile_url,
        headers=headers,
        params=params,
        json=json_data,
        cookies=cookie,
    )
    # print(response.text)
    return response


if __name__ == "__main__":
    with sync_playwright() as p:
        for browser_type in [p.chromium]:
            browser = browser_type.launch(devtools=True)
            page = browser.new_page()
            print("login the overleaf page")
            page.goto(login_url)
            page.type(account_input, account)
            page.type(password_input, password)
            page.click(submit_btn)
            print("go to project URL")
            page.screenshot(path=f"login-{browser_type.name}.png")
            page.wait_for_url(project_url, timeout=WAIT_TIMEOUT)
            # page.screenshot(path=f"project-{browser_type.name}.png")
            # page.goto(page_url)
            # page.wait_for_url(page_url, timeout=WAIT_TIMEOUT)
            # page.screenshot(path=f"page-{browser_type.name}.png")
            # content = page.content()
            # csrf_token = get_csrf_token(content)
            # # print(csrf_token)
            # cookie = page.context.cookies()
            # # print(cookie)
            # accepted_cookie = {"GCLB", "overleaf_session2"}
            # cookies = {
            #     c["name"]: c["value"] for c in cookie if c["name"] in accepted_cookie
            # }
            # # print(cookies)
            # print("call overleaf compile API")
            # compile_response = compile(csrf_token, cookies)
            # print("starts to download the resume pdf")
            # download_resume(compile_response, cookies)
            # browser.close()
