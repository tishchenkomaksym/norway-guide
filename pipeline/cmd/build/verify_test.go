package main

import (
	"database/sql"
	"os"
	"testing"

	_ "modernc.org/sqlite"
)

// Проверяем собранную базу теми же запросами, которыми ходит приложение.
// Если fallback-цепочка или FTS сломаны, узнать это надо здесь, а не на
// устройстве.
//
// Тест пропускается, когда базы нет: она собирается вручную из данных,
// которых нет в репозитории.
const dbPath = "../../data/content.sqlite"

func openDB(t *testing.T) *sql.DB {
	t.Helper()
	if _, err := os.Stat(dbPath); os.IsNotExist(err) {
		t.Skip("нет собранной базы, пропускаем: запустите cmd/build")
	}
	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { db.Close() })
	return db
}

func TestБазаНеПустая(t *testing.T) {
	db := openDB(t)

	var places, cities int
	if err := db.QueryRow("SELECT COUNT(*) FROM places").Scan(&places); err != nil {
		t.Fatal(err)
	}
	if err := db.QueryRow("SELECT COUNT(*) FROM cities").Scan(&cities); err != nil {
		t.Fatal(err)
	}
	if places == 0 {
		t.Error("в базе нет мест")
	}
	if cities == 0 {
		t.Error("в базе нет городов")
	}
	t.Logf("мест %d, городов %d", places, cities)
}

func TestFallbackЦепочка(t *testing.T) {
	db := openDB(t)

	// Тот же запрос, что в app/lib/data/database.dart: язык пользователя →
	// en → no → норвежское имя из OSM.
	const q = `
		SELECT COALESCE(t_user.name, t_en.name, p.name_no)          AS res_name,
		       CASE WHEN t_user.summary IS NULL THEN 1 ELSE 0 END   AS is_fallback
		FROM places p
		LEFT JOIN translations t_user
		       ON t_user.entity_type='place' AND t_user.entity_id=p.id AND t_user.lang=?
		LEFT JOIN translations t_en
		       ON t_en.entity_type='place'   AND t_en.entity_id=p.id   AND t_en.lang='en'
		WHERE p.id = (SELECT id FROM places ORDER BY importance DESC LIMIT 1)`

	var name string
	var fallback int
	if err := db.QueryRow(q, "ru").Scan(&name, &fallback); err != nil {
		t.Fatal(err)
	}
	if name == "" {
		t.Error("имя пустое — цепочка подстановки не сработала")
	}
	// Русских текстов пайплайн пока не собирает, значит должен быть fallback.
	if fallback != 1 {
		t.Errorf("ожидался признак fallback для языка без переводов, получено %d", fallback)
	}
	t.Logf("самое значимое место: %q, fallback=%d", name, fallback)
}

func TestПоискFTS(t *testing.T) {
	db := openDB(t)

	var n int
	err := db.QueryRow(
		`SELECT COUNT(*) FROM search_fts WHERE search_fts MATCH ?`, "bry*",
	).Scan(&n)
	if err != nil {
		t.Fatalf("префиксный поиск не работает: %v", err)
	}
	if n == 0 {
		t.Error("префиксный поиск ничего не нашёл — проверьте наполнение индекса")
	}
	t.Logf("по запросу bry* найдено %d строк", n)
}

func TestМестаПривязаныКГородам(t *testing.T) {
	db := openDB(t)

	var orphans int
	err := db.QueryRow(
		`SELECT COUNT(*) FROM places WHERE city_id IS NOT NULL
		   AND city_id NOT IN (SELECT id FROM cities)`).Scan(&orphans)
	if err != nil {
		t.Fatal(err)
	}
	if orphans > 0 {
		t.Errorf("%d мест ссылаются на несуществующие города", orphans)
	}
}

func TestПланЗапросаПоКоординатам(t *testing.T) {
	db := openDB(t)

	var places int
	if err := db.QueryRow("SELECT COUNT(*) FROM places").Scan(&places); err != nil {
		t.Fatal(err)
	}

	// Плейсхолдеры в EXPLAIN QUERY PLAN дают пустой результат, поэтому
	// значения подставлены в текст запроса.
	rows, err := db.Query(`EXPLAIN QUERY PLAN
		SELECT id FROM places
		WHERE lat BETWEEN 60.0 AND 60.5 AND lon BETWEEN 5.0 AND 5.6`)
	if err != nil {
		t.Fatal(err)
	}
	defer rows.Close()

	plan := ""
	for rows.Next() {
		var id, parent, notUsed int
		var detail string
		if err := rows.Scan(&id, &parent, &notUsed, &detail); err != nil {
			t.Fatal(err)
		}
		plan += detail + "\n"
	}
	t.Logf("мест %d, план запроса: %s", places, plan)

	// На малой базе планировщик после ANALYZE справедливо выбирает полный
	// скан: обращение к индексу дороже. Требовать индекс здесь — значит
	// проверять не то. А вот на боевом объёме скан недопустим: список
	// «рядом со мной» строится на каждое движение фильтра.
	const scanIsFineBelow = 5000
	if places >= scanIsFineBelow && !contains(plan, "idx_places_geo") {
		t.Errorf("на %d местах запрос по координатам идёт полным сканом:\n%s",
			places, plan)
	}
	if places < scanIsFineBelow && !contains(plan, "idx_places_geo") {
		t.Logf("полный скан на малой базе — ожидаемо; "+
			"проверить заново после сборки по всей Норвегии (%d < %d)",
			places, scanIsFineBelow)
	}
}

func contains(s, sub string) bool {
	for i := 0; i+len(sub) <= len(s); i++ {
		if s[i:i+len(sub)] == sub {
			return true
		}
	}
	return false
}
