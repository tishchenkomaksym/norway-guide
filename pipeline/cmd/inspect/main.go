// Команда inspect — заглянуть в собранную базу глазами приложения.
//
// Нужна при подборе формул ранжирования: увидеть порядок городов проще
// в таблице, чем в интерфейсе, где он смешан с вёрсткой.
//
// Запуск: go run ./cmd/inspect --db data/content.sqlite
package main

import (
	"database/sql"
	"flag"
	"fmt"
	"os"

	_ "modernc.org/sqlite"
)

func main() {
	dbPath := flag.String("db", "data/content.sqlite", "база")
	flag.Parse()

	db, err := sql.Open("sqlite", *dbPath)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	defer db.Close()

	// Тот же запрос, что в AppDatabase.cityCards.
	rows, err := db.Query(`
      WITH city_stats AS (
        SELECT c.id,
               (SELECT COUNT(*) FROM places p WHERE p.city_id = c.id) AS place_count,
               (SELECT COUNT(*) FROM places p
                 WHERE p.city_id = c.id AND p.importance >= 65)       AS notable_count,
               (SELECT COALESCE(MAX(p.importance), 0) FROM places p
                 WHERE p.city_id = c.id)                             AS best_place
        FROM cities c)
      SELECT c.name_no, COALESCE(c.population, 0), s.place_count,
             s.notable_count, s.best_place,
             (s.best_place
              + MIN(s.notable_count, 10) * 4
              + CASE
                  WHEN c.population >= 100000 THEN 20
                  WHEN c.population >= 20000  THEN 12
                  WHEN c.population >= 5000   THEN 6
                  ELSE 0
                END) AS tourist_score
      FROM cities c
      JOIN city_stats s ON s.id = c.id
      WHERE s.notable_count >= 1 OR c.population >= 20000
      ORDER BY tourist_score DESC, s.place_count DESC`)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	defer rows.Close()

	fmt.Printf("%-22s %9s %6s %7s %7s %7s\n",
		"город", "жителей", "мест", "заметн", "лучшее", "оценка")
	for rows.Next() {
		var name string
		var pop, places, notable, best, score int
		if err := rows.Scan(&name, &pop, &places, &notable, &best, &score); err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		fmt.Printf("%-22s %9d %6d %7d %7d %7d\n",
			name, pop, places, notable, best, score)
	}
}
