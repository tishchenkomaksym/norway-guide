//go:build ignore

package main

import (
	"database/sql"
	"fmt"
	"sort"

	"github.com/grigorianez/nordguide/pipeline/internal/regions"
	_ "modernc.org/sqlite"
)

func main() {
	db, _ := sql.Open("sqlite", "data/content.sqlite")
	defer db.Close()

	type stat struct {
		places, withPhoto, photos int
	}
	byRegion := map[string]*stat{}

	rows, err := db.Query(`
	  SELECT p.lat, p.lon,
	         (SELECT COUNT(*) FROM photos ph WHERE ph.place_id = p.id)
	    FROM places p`)
	if err != nil {
		fmt.Println("ошибка:", err)
		return
	}
	defer rows.Close()
	for rows.Next() {
		var lat, lon float64
		var n int
		rows.Scan(&lat, &lon, &n)
		r := regions.For(lat, lon)
		s := byRegion[r.ID]
		if s == nil {
			s = &stat{}
			byRegion[r.ID] = s
		}
		s.places++
		s.photos += n
		if n > 0 {
			s.withPhoto++
		}
	}

	ids := make([]string, 0, len(byRegion))
	for id := range byRegion {
		ids = append(ids, id)
	}
	sort.Slice(ids, func(i, j int) bool {
		return byRegion[ids[i]].places > byRegion[ids[j]].places
	})

	fmt.Printf("%-12s %8s %10s %8s\n", "регион", "мест", "с фото", "снимков")
	total := 0
	for _, id := range ids {
		s := byRegion[id]
		total += s.places
		fmt.Printf("%-12s %8d %10d %8d\n", id, s.places, s.withPhoto, s.photos)
	}
	fmt.Printf("%-12s %8d\n", "всего", total)

	if s := byRegion["other"]; s != nil && s.places > total/20 {
		fmt.Printf("\nВНИМАНИЕ: в уловитель попало %d мест (%d%%) — границы регионов с дырами\n",
			s.places, s.places*100/total)
	} else {
		fmt.Println("\nУловитель почти пуст — регионы покрывают страну")
	}
}
