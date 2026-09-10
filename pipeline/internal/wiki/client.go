// Package wiki обращается к Wikidata, Wikipedia и Wikivoyage.
package wiki

import (
	"crypto/sha1"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"
)

const UserAgent = "nordguide/0.1 (offline Norway guide; https://github.com/grigorianez/nordguide)"

// Client — общий клиент для всех вики-проектов.
//
// Три вещи, без которых этап обогащения не работает:
//
//  1. Лимит скорости. Wikipedia отдаёт 429 на частые анонимные запросы.
//     Это уже дважды приводило к тому, что разведка молча показывала
//     нулевое покрытие — сбой выглядел как «статьи нет».
//  2. Дисковый кэш. Прогон по всей Норвегии — десятки тысяч запросов;
//     повторный запуск после правки парсера не должен качать заново.
//  3. Честные ошибки. Сбой запроса НИКОГДА не превращается в пустой
//     результат: пустота означает «статьи действительно нет», и спутать
//     эти два случая — значит потерять контент, не заметив этого.
type Client struct {
	http     *http.Client
	cacheDir string
	interval time.Duration
	last     time.Time

	// Статистика для отчёта.
	Requests  int
	CacheHits int
	Retries   int
}

func NewClient(cacheDir string) (*Client, error) {
	if err := os.MkdirAll(cacheDir, 0o755); err != nil {
		return nil, fmt.Errorf("кэш: %w", err)
	}
	return &Client{
		http:     &http.Client{Timeout: 45 * time.Second},
		cacheDir: cacheDir,
		interval: 400 * time.Millisecond, // ~2.5 запроса в секунду
	}, nil
}

// SetRate меняет паузу между запросами.
func (c *Client) SetRate(d time.Duration) { c.interval = d }

func (c *Client) cachePath(url string) string {
	sum := sha1.Sum([]byte(url))
	name := hex.EncodeToString(sum[:])
	// Раскладываем по подкаталогам: десятки тысяч файлов в одной папке
	// заметно замедляют файловую систему.
	return filepath.Join(c.cacheDir, name[:2], name+".json")
}

// GetJSON выполняет запрос и разбирает ответ в out.
//
// Кэш безусловный и без срока: вики-статьи для наших целей меняются
// медленнее, чем идёт разработка. Чтобы обновить данные, каталог кэша
// удаляется целиком.
func (c *Client) GetJSON(url string, out any) error {
	path := c.cachePath(url)
	if data, err := os.ReadFile(path); err == nil {
		c.CacheHits++
		return json.Unmarshal(data, out)
	}

	data, err := c.fetch(url)
	if err != nil {
		return err
	}

	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	// Пишем через временный файл: прерванный прогон не должен оставить
	// в кэше обрезанный JSON, который потом молча разберётся как пустой.
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, data, 0o644); err != nil {
		return err
	}
	if err := os.Rename(tmp, path); err != nil {
		return err
	}

	return json.Unmarshal(data, out)
}

func (c *Client) fetch(url string) ([]byte, error) {
	const maxAttempts = 4
	backoff := 2 * time.Second

	for attempt := 1; ; attempt++ {
		// Соблюдаем интервал между обращениями к сети.
		if wait := c.interval - time.Since(c.last); wait > 0 {
			time.Sleep(wait)
		}
		c.last = time.Now()
		c.Requests++

		req, err := http.NewRequest("GET", url, nil)
		if err != nil {
			return nil, err
		}
		req.Header.Set("User-Agent", UserAgent)
		// Accept-Encoding вручную не ставим: Go добавляет его сам и
		// прозрачно распаковывает. Заданный руками заголовок эту
		// распаковку отключает, и в парсер приходят сжатые байты.

		resp, err := c.http.Do(req)
		if err != nil {
			if attempt >= maxAttempts {
				return nil, fmt.Errorf("%s: %w", url, err)
			}
			c.Retries++
			time.Sleep(backoff)
			backoff *= 2
			continue
		}

		if resp.StatusCode == http.StatusTooManyRequests || resp.StatusCode >= 500 {
			retryAfter := resp.Header.Get("Retry-After")
			resp.Body.Close()
			if attempt >= maxAttempts {
				return nil, fmt.Errorf("%s: HTTP %d после %d попыток",
					url, resp.StatusCode, attempt)
			}
			c.Retries++
			if secs, e := strconv.Atoi(retryAfter); e == nil {
				time.Sleep(time.Duration(secs) * time.Second)
			} else {
				time.Sleep(backoff)
			}
			backoff *= 2
			continue
		}

		body, err := io.ReadAll(resp.Body)
		resp.Body.Close()
		if err != nil {
			return nil, fmt.Errorf("%s: чтение ответа: %w", url, err)
		}
		if resp.StatusCode != http.StatusOK {
			return nil, fmt.Errorf("%s: HTTP %d", url, resp.StatusCode)
		}
		return body, nil
	}
}
