"""
==============================================================================
Module: app.py
Description: Lightweight local web dashboard server for Olist E-Commerce
             Revenue Segmentation & Regional Heatmap Analytics.
             Serves the responsive dashboard_preview.html with live metrics.
==============================================================================
"""

import os
import webbrowser
import http.server
import socketserver

PORT = 8055
PROJECT_ROOT = os.path.abspath(os.path.dirname(__file__))
HTML_PATH = os.path.join(PROJECT_ROOT, "outputs", "dashboard_preview.html")


class DashboardHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path in ("/", "/dashboard", "/index.html"):
            self.send_response(200)
            self.send_header("Content-type", "text/html; charset=utf-8")
            self.end_headers()
            with open(HTML_PATH, "rb") as f:
                self.wfile.write(f.read())
        else:
            super().do_GET()


def start_server():
    os.chdir(PROJECT_ROOT)
    print("=" * 75)
    print("  [*] OLIST E-COMMERCE REVENUE SEGMENTATION DASHBOARD SERVER")
    print(f"  [*] Serving locally at: http://localhost:{PORT}")
    print("  [*] Press Ctrl+C to terminate.")
    print("=" * 75)

    webbrowser.open(f"http://localhost:{PORT}")

    with socketserver.TCPServer(("", PORT), DashboardHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n  [*] Server stopped.")


if __name__ == "__main__":
    start_server()
