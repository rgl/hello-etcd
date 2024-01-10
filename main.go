package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"sort"
	"strconv"
	"strings"
	"time"

	etcd "go.etcd.io/etcd/client/v3"
)

var (
	version  string = "0.0.0-dev"
	revision string = "0000000000000000000000000000000000000000"
)

// very naive implementation of a counter.
func incrementHitCounter(ctx context.Context, cli *etcd.Client) int64 {
	kv := etcd.NewKV(cli)
	for {
		r, err := kv.Get(ctx, "hit-counter")
		if err != nil {
			log.Printf("WARN failed to get hit-counter: %v", err)
			continue
		}
		previousHitCounterValue := "0"
		if len(r.Kvs) != 0 {
			previousHitCounterValue = string(r.Kvs[0].Value)
		}
		hitCounter, err := strconv.ParseInt(previousHitCounterValue, 10, 64)
		if err != nil {
			log.Printf("WARN failed to get hit-counter: %v", err)
			continue
		}
		hitCounter = hitCounter + 1
		_, err = kv.Put(ctx, "hit-counter", strconv.FormatInt(hitCounter, 10))
		if err != nil {
			log.Printf("WARN failed to set hit-counter: %v", err)
			continue
		}
		return hitCounter
	}
}

func main() {
	log.SetFlags(0)

	var showVersion = flag.Bool("version", false, "Show version and exit.")
	var listenAddress = flag.String("listen", ":8888", "Listen address.")
	var etcdAddress = flag.String("etcd-address", "etcd:2379", "etcd address.")

	flag.Parse()

	if *showVersion {
		fmt.Printf("v%s+%s\n", version, revision)
		return
	}

	if flag.NArg() != 0 {
		flag.Usage()
		log.Fatalf("\nYou MUST NOT pass any positional arguments")
	}

	cli, err := etcd.New(etcd.Config{
		Endpoints:   []string{*etcdAddress},
		DialTimeout: 5 * time.Second,
	})
	if err != nil {
		log.Fatalf("Failed to create etcd client: %v", err)
	}
	defer cli.Close()

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Printf("%s %s%s\n", r.Method, r.Host, r.URL)

		if r.URL.Path != "/" {
			w.WriteHeader(404)
			return
		}

		hitCounter := incrementHitCounter(context.TODO(), cli)

		fmt.Fprintf(
			w,
			`Hello World #%d!

Client Request: %s %s%s
Client Address: %s
Server Address: %s
Hello Version: v%s+%s
`,
			hitCounter,
			r.Method,
			r.Host,
			r.URL,
			r.RemoteAddr,
			r.Context().Value(http.LocalAddrContextKey).(net.Addr).String(),
			version,
			revision)

		var helloVars []string
		for _, e := range os.Environ() {
			if strings.HasPrefix(e, "HELLO_") {
				helloVars = append(helloVars, e)
			}
		}
		sort.Strings(helloVars)
		for _, e := range helloVars {
			fmt.Fprintf(w, "Hello Environment Variable: %s\n", e)
		}
	})

	fmt.Printf("Listening at http://%s\n", *listenAddress)

	err = http.ListenAndServe(*listenAddress, nil)
	if err != nil {
		log.Fatalf("Failed to ListenAndServe: %v", err)
	}
}
