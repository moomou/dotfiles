package main

import (
	"fmt"
	"log"
	"net"
	"net/http"
	"os"

	"github.com/mdp/qrterminal"
)

const PORT = 8082

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

func main() {
	fmt.Printf("Serving files in the current directory on port %d", PORT)

	printLocationQR(PORT)

	http.Handle("/", http.FileServer(http.Dir(".")))
	err := http.ListenAndServe(":8082", nil)

	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}

}
