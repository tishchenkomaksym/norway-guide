//go:build ignore

package main

import (
	"database/sql"
	"fmt"
	"os"
	"path/filepath"

	"github.com/grigorianez/nordguide/pipeline/internal/regions"
	_ "modernc.org/sqlite"
)

// Где разрезать тяжёлый регион: смотрим распределение снимков внутри него.
func main() {
	db, _ := sql.Open("sqlite", "data/content.sqlite")
	defer db.Close()

	rows, err := db.Query(`
	  SELECT ph.path_thumb, p.lat, p.lon
	    FROM photos ph JOIN places p ON p.id = ph.place_id
	   WHERE p.top_rank = 0
	  UNION ALL
	  SELECT ph.path_thumb, c.lat, c.lon
	    FROM photos ph JOIN cities c ON c.id = ph.city_id`)
	if err != nil {
		fmt.Println("ошибка:", err)
		return
	}
	defer rows.Close()

	type cell struct {
		count int
		bytes int64
	}
	// Внутри east смотрим по долготе: Осло на востоке, Йотунхеймен западнее.
	byLon := map[int]*cell{}
	var total int64
	var n int

	for rows.Next() {
		var path string
		var lat, lon float64
		rows.Scan(&path, &lat, &lon)
		if regions.For(lat, lon).ID != "east" {
			continue
		}
		info, err := os.Stat(filepath.Join("../app/assets/photos", filepath.Base(path)))
		if err != nil {
			continue
		}
		key := int(lon)
		c := byLon[key]
		if c == nil {
			c = &cell{}
			byLon[key] = c
		}
		c.count++
		c.bytes += info.Size()
		total += info.Size()
		n++
	}

	fmt.Printf("Регион east: %d снимков, %.1f МБ\n\n", n, float64(total)/(1<<20))
	fmt.Println("по долготе:")
	for lon := 7; lon <= 13; lon++ {
		if c := byLon[lon]; c != nil {
			fmt.Printf("  %2d°..%2d°  %4d снимков  %6.1f МБ\n",
				lon, lon+1, c.count, float64(c.bytes)/(1<<20))
		}
	}

	// Осло и окрестности — самый плотный кусок.
	var osloBytes int64
	var osloCount int
	rows2, _ := db.Query(`
	  SELECT ph.path_thumb, p.lat, p.lon FROM photos ph
	    JOIN places p ON p.id = ph.place_id WHERE p.top_rank = 0
	  UNION ALL
	  SELECT ph.path_thumb, c.lat, c.lon FROM photos ph
	    JOIN cities c ON c.id = ph.city_id`)
	defer rows2.Close()
	for rows2.Next() {
		var path string
		var lat, lon float64
		rows2.Scan(&path, &lat, &lon)
		if lat >= 59.5 && lat <= 60.3 && lon >= 10.0 && lon <= 11.3 {
			if info, err := os.Stat(filepath.Join("../app/assets/photos",
				filepath.Base(path))); err == nil {
				osloCount++
				osloBytes += info.Size()
			}
		}
	}
	fmt.Printf("\nОсло и окрестности (59.5-60.3, 10.0-11.3): %d снимков, %.1f МБ\n",
		osloCount, float64(osloBytes)/(1<<20))
}
