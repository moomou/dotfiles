package main

import (
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"strconv"

	"github.com/mdp/qrterminal"
)

const DEFAULT_PORT = 8082
const MAX_PORT_SCAN = 100

var privateIPBlocks []*net.IPNet

func init() {
	for _, cidr := range []string{
		"127.0.0.0/8",    // IPv4 loopback
		"10.0.0.0/8",     // RFC1918
		"172.16.0.0/12",  // RFC1918
		"192.168.0.0/16", // RFC1918
		// TODO: look into IPv6
		//"::1/128",        // IPv6 loopback
		//"fe80::/10",      // IPv6 link-local
		//"fc00::/7",       // IPv6 unique local addr
	} {
		_, block, err := net.ParseCIDR(cidr)
		if err != nil {
			panic(fmt.Errorf("parse error on %q: %v", cidr, err))
		}
		privateIPBlocks = append(privateIPBlocks, block)
	}
}

func isPrivateIP(ip net.IP) bool {
	for _, block := range privateIPBlocks {
		if block.Contains(ip) {
			return true
		}
	}
	return false
}

func printLocationQR(port int) {
	config := qrterminal.Config{
		Level:     qrterminal.L,
		Writer:    os.Stdout,
		BlackChar: qrterminal.WHITE,
		WhiteChar: qrterminal.BLACK,
		QuietZone: 1,
	}

	ifaces, err := net.Interfaces()
	if err != nil {
		panic(err)
	}

	for _, i := range ifaces {
		addrs, err := i.Addrs()
		if err != nil {
			continue
		}
		// handle err
		for _, addr := range addrs {
			var ip net.IP
			switch v := addr.(type) {
			case *net.IPNet:
				ip = v.IP
			case *net.IPAddr:
				ip = v.IP
			}

			if isPrivateIP(ip) && !ip.IsLoopback() {
				loc := fmt.Sprintf("http://%s:%d", ip.String(), port)
				fmt.Printf("\n\nUse QR code to visit at %s\n\n", loc)
				qrterminal.GenerateWithConfig(loc, config)
			}
		}
	}

}

func listenFromPort(start int) (net.Listener, int, error) {
	for p := start; p < start+MAX_PORT_SCAN; p++ {
		ln, err := net.Listen("tcp", fmt.Sprintf(":%d", p))
		if err == nil {
			return ln, p, nil
		}
	}
	return nil, 0, fmt.Errorf("no available port in range %d-%d", start, start+MAX_PORT_SCAN-1)
}

func main() {
	dir, err := os.Getwd()
	if err != nil {
		fmt.Printf("cannot list current dir:: %s\n", err)
		os.Exit(1)
	}

	if len(os.Args) >= 2 {
		dir = os.Args[1]
	}

	var ln net.Listener
	var port int

	if len(os.Args) >= 3 {
		port, err = strconv.Atoi(os.Args[2])
		if err != nil {
			fmt.Printf("invalid port %q: %s\n", os.Args[2], err)
			os.Exit(1)
		}
		ln, err = net.Listen("tcp", fmt.Sprintf(":%d", port))
		if err != nil {
			log.Fatalf("cannot bind port %d: %s", port, err)
		}
	} else {
		ln, port, err = listenFromPort(DEFAULT_PORT)
		if err != nil {
			log.Fatal(err)
		}
	}

	fmt.Printf("Serving files in the %s on port %d", dir, port)

	printLocationQR(port)

	http.Handle("/", http.FileServer(http.Dir(dir)))

	if err := http.Serve(ln, nil); err != nil {
		log.Fatal("Serve: ", err)
	}

}
