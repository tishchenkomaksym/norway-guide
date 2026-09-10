package osm

import "testing"

func TestClassify(t *testing.T) {
	cases := []struct {
		name string
		tags map[string]string
		want string
		ok   bool
	}{
		{
			name: "водопад по natural",
			tags: map[string]string{"natural": "waterfall", "name": "Vøringsfossen"},
			want: CatWaterfall,
			ok:   true,
		},
		{
			name: "ледник",
			tags: map[string]string{"natural": "glacier", "name": "Nigardsbreen"},
			want: CatGlacier,
			ok:   true,
		},
		{
			name: "ставкирка важнее общего historic",
			tags: map[string]string{"historic": "church", "building": "church"},
			want: CatChurch,
			ok:   true,
		},
		{
			name: "музей",
			tags: map[string]string{"tourism": "museum"},
			want: CatMuseum,
			ok:   true,
		},
		{
			name: "смотровая площадка",
			tags: map[string]string{"tourism": "viewpoint"},
			want: CatViewpoint,
			ok:   true,
		},
		{
			name: "заправка нам не нужна",
			tags: map[string]string{"amenity": "fuel"},
			ok:   false,
		},
		{
			name: "жилой дом нам не нужен",
			tags: map[string]string{"building": "house"},
			ok:   false,
		},
	}

	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			got, _, ok := Classify(c.tags)
			if ok != c.ok {
				t.Fatalf("ok = %v, ожидалось %v", ok, c.ok)
			}
			if ok && got != c.want {
				t.Errorf("категория = %q, ожидалось %q", got, c.want)
			}
		})
	}
}

func TestImportance(t *testing.T) {
	t.Run("ссылка на wikidata сильно поднимает", func(t *testing.T) {
		plain := Importance(map[string]string{}, 20)
		linked := Importance(map[string]string{"wikidata": "Q1"}, 20)
		if linked <= plain {
			t.Errorf("с wikidata %d, без %d — должно быть больше", linked, plain)
		}
	})

	t.Run("не выходит за 100", func(t *testing.T) {
		got := Importance(map[string]string{
			"wikidata":          "Q1",
			"wikipedia":         "no:Test",
			"website":           "https://example.no",
			"opening_hours":     "24/7",
			"heritage":          "1",
			"heritage:operator": "whc",
			"tourism":           "attraction",
		}, 40)
		if got > 100 {
			t.Errorf("значимость %d превышает 100", got)
		}
	})

	t.Run("не уходит ниже нуля", func(t *testing.T) {
		if got := Importance(map[string]string{}, 0); got < 0 {
			t.Errorf("значимость %d меньше нуля", got)
		}
	})
}

func TestName(t *testing.T) {
	t.Run("норвежское имя приоритетнее общего", func(t *testing.T) {
		got := Name(map[string]string{"name": "Bergen", "name:no": "Bergen by"})
		if got != "Bergen by" {
			t.Errorf("имя = %q, ожидалось name:no", got)
		}
	})

	t.Run("без имени пусто", func(t *testing.T) {
		if got := Name(map[string]string{"natural": "peak"}); got != "" {
			t.Errorf("имя = %q, ожидалась пустая строка", got)
		}
	})
}

func TestFromTagsОтбрасываетБезымянные(t *testing.T) {
	_, ok := FromTags("osm:node/1", map[string]string{"natural": "waterfall"}, 60, 5)
	if ok {
		t.Error("объект без имени не должен извлекаться")
	}
}

func TestTagsЮнеско(t *testing.T) {
	tags := Tags(map[string]string{"heritage:operator": "whc"}, CatChurch)
	found := false
	for _, tag := range tags {
		if tag == "unesco" {
			found = true
		}
	}
	if !found {
		t.Error("объект ЮНЕСКО должен получать тег unesco")
	}
}
