package main

import (
	"golang.org/x/net/proxy"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
)

func main() {
	// Create target URL
	target, err := url.Parse("https://huggingface.co")
	if err != nil {
		panic(err)
	}

	// Create SOCKS5 dialer
	socksProxy := os.Getenv("SOCKS_PROXY")
	if socksProxy == "" {
		socksProxy = "http-proxy-to-socks:8080" // Default value if not set
	}
	dialer, err := proxy.SOCKS5("tcp", socksProxy, nil, proxy.Direct)
	if err != nil {
		panic(err)
	}

	// Create transport with SOCKS5 dialer
	transport := &http.Transport{
		Dial: dialer.Dial,
	}

	// Create reverse proxy
	proxy := httputil.NewSingleHostReverseProxy(target)
	proxy.Transport = transport

	// Customize director to modify requests before forwarding
	originalDirector := proxy.Director
	proxy.Director = func(req *http.Request) {
		originalDirector(req)

		// Set headers
		req.Host = target.Host
		req.Header.Set("Referer", target.String())
	}

	// Customize response modifier
	proxy.ModifyResponse = func(resp *http.Response) error {
		// Set CORS headers
		resp.Header.Set("Access-Control-Allow-Origin", "*")
		resp.Header.Set("Access-Control-Allow-Credentials", "true")

		// Remove security headers
		resp.Header.Del("Content-Security-Policy")
		resp.Header.Del("Content-Security-Policy-Report-Only")
		resp.Header.Del("Clear-Site-Data")

		return nil
	}

	// Start server
	server := &http.Server{
		Addr:    ":6767",
		Handler: proxy,
	}

	if err := server.ListenAndServe(); err != nil {
		panic(err)
	}
}
