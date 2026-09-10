package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"time"

	"github.com/grigorianez/nordguide/pipeline/internal/wiki"
)

var httpClient = &http.Client{Timeout: 90 * time.Second}

// runCurl скачивает файл по адресу в dest.
//
// Имя историческое: сначала здесь действительно вызывался curl. Обычный
// http-клиент оказался и проще, и надёжнее — не нужно разбирать чужой код
// возврата и гадать, что означает пустой файл.
func runCurl(url, dest string) error {
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return err
	}
	req.Header.Set("User-Agent", wiki.UserAgent)

	resp, err := httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("HTTP %d", resp.StatusCode)
	}

	f, err := os.Create(dest)
	if err != nil {
		return err
	}
	defer f.Close()

	if _, err := io.Copy(f, resp.Body); err != nil {
		return err
	}
	return nil
}
