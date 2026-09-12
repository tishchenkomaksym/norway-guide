//go:build ignore

package main

import (
	"database/sql"
	"fmt"
	"os"

	_ "modernc.org/sqlite"
)

// Из чего состоит база: что выгоднее ужимать.
func main() {
	db, _ := sql.Open("sqlite", "data/content.sqlite")
	defer db.Close()

	info, _ := os.Stat("data/content.sqlite")
	fmt.Printf("Файл базы: %.1f МБ\n\n", float64(info.Size())/(1<<20))

	type row struct {
		name  string
		bytes int64
	}
	var rows []row

	q := func(name, sql string) {
		var n sql2
		_ = n
	}
	_ = q

	queries := map[string]string{
		"тексты: description": `SELECT SUM(LENGTH(description)) FROM translations`,
		"тексты: summary":     `SELECT SUM(LENGTH(summary)) FROM translations`,
		"тексты: name":        `SELECT SUM(LENGTH(name)) FROM translations`,
		"поисковый индекс":    `SELECT SUM(LENGTH(name) + LENGTH(description)) FROM search_fts`,
	}
	for name, sqlText := range queries {
		var n sql.NullInt64
		db.QueryRow(sqlText).Scan(&n)
		rows = append(rows, row{name, n.Int64})
	}

	for _, r := range rows {
		fmt.Printf("  %-22s %6.1f МБ\n", r.name, float64(r.bytes)/(1<<20))
	}

	// Сколько строк и какой средней длины
	var count int
	var avg float64
	db.QueryRow(`SELECT COUNT(*), AVG(LENGTH(description)) FROM translations
	              WHERE description IS NOT NULL`).Scan(&count, &avg)
	fmt.Printf("\nописаний: %d, средняя длина %.0f символов\n", count, avg)

	var sameCount int
	db.QueryRow(`SELECT COUNT(*) FROM translations
	              WHERE description = summary`).Scan(&sameCount)
	fmt.Printf("описание совпадает с кратким: %d\n", sameCount)
}

type sql2 = int
