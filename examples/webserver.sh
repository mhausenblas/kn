while true ; do nc -l -p 8080 -c 'echo -e "HTTP/1.1 200 OK\n\n $(date)"'; done