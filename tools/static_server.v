module main

import net.http
import os

fn main() {
	root := if os.args.len > 1 { os.args[1] } else { os.getwd() }
	port := if os.args.len > 2 { os.args[2].int() } else { 8902 }
	mut server := http.Server{
		addr:                 '127.0.0.1:${port}'
		handler:              StaticHandler{
			root: root
		}
		show_startup_message: true
	}
	server.listen_and_serve()
}

struct StaticHandler {
	root string
}

fn (handler StaticHandler) handle(req http.Request) http.Response {
	mut rel := req.url.trim_left('/').split('?')[0]
	if rel == '' {
		rel = 'index.html'
	}
	path := os.join_path(handler.root, rel)
	if !os.exists(path) || !os.is_file(path) {
		return response(404, 'not found', 'text/plain; charset=utf-8')
	}
	return response(200, os.read_file(path) or { '' }, content_type(path))
}

fn response(status int, body string, content_type string) http.Response {
	return http.Response{
		status_code:  status
		status_msg:   if status == 200 { 'OK' } else { 'Not Found' }
		http_version: '1.1'
		header:       http.new_header_from_map({
			http.CommonHeader.content_type: content_type
		})
		body:         body
	}
}

fn content_type(path string) string {
	ext := os.file_ext(path)
	return match ext {
		'.html' { 'text/html; charset=utf-8' }
		'.vue' { 'text/plain; charset=utf-8' }
		'.svg' { 'image/svg+xml' }
		'.js' { 'text/javascript; charset=utf-8' }
		'.css' { 'text/css; charset=utf-8' }
		else { 'text/plain; charset=utf-8' }
	}
}
