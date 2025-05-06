package main

import (
    "bufio"
    "bytes"
    "fmt"
    "io"
    "net/http"
    "sync"
    "time"
)

const (
    url            = "http://localhost:4000/sse"
	token          = "Bearer eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxfQ.rINrV4jad74K9b1W39TEKlqXpG63h-dn-yfqQpVEztuhomwW4lZ36j6cKl9IXLiq43zvmNjBlMOA_aCbgofQOg"
    clients        = 100
    reconnectDelay = 5 * time.Second
)

var (
    connectedClients int
    mu               sync.Mutex
)

func main() {
    var wg sync.WaitGroup
    wg.Add(clients)

    for i := 0; i < clients; i++ {
        go func(clientID int) {
            defer wg.Done()
            connect(clientID)
        }(i)
    }

    wg.Wait()
}

func connect(clientID int) {
    for {
        client := &http.Client{}

        body := []byte(`{"channels":["order.us.deliver", "order.eu.deliver"]}`)

        req, err := http.NewRequest("POST", url, io.NopCloser(bytes.NewReader(body)))
        if err != nil {
            fmt.Printf("Client %d: Error creating request: %v\n", clientID, err)
            return
        }

        req.Header.Set("Accept", "text/event-stream")
        req.Header.Set("Content-Type", "application/json")
        req.Header.Set("Cache-Control", "no-cache")
        req.Header.Set("Connection", "keep-alive")
        req.Header.Set("Authorization", token)

        resp, err := client.Do(req)
        if err != nil {
            fmt.Printf("Client %d: Error making request: %v\n", clientID, err)
            time.Sleep(reconnectDelay)
            continue
        }

        // Increment the connected clients count
        mu.Lock()
        connectedClients++
        fmt.Printf("Client %d connected. Total connected clients: %d\n", clientID, connectedClients)
        mu.Unlock()

        reader := bufio.NewReader(resp.Body)
        for {
            line, err := reader.ReadBytes('\n')
            if err != nil {
                if err == io.EOF {
                    fmt.Printf("Client %d: Connection closed by server\n", clientID)
                } else {
                    fmt.Printf("Client %d: Error reading response: %v\n", clientID, err)
                }
                resp.Body.Close()

                // Decrement the connected clients count
                mu.Lock()
                connectedClients--
                fmt.Printf("Client %d disconnected. Total connected clients: %d\n", clientID, connectedClients)
                mu.Unlock()

                break
            }

            // Log the received message
            fmt.Printf("Client %d: Received event: %s\n", clientID, string(line))
        }

        fmt.Printf("Client %d: Reconnecting...\n", clientID)
        time.Sleep(reconnectDelay)
    }
}