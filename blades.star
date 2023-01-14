load("render.star", "render")
load("http.star", "http")
load("html.star", "html")
load("cache.star", "cache")
load("encoding/json.star", "json")

BLADES_STATS_URL = "http://stats.nchl.com/site/3333/page.asp?Site=9818&page=Teams&LeagueID=9818&SeasonID=40&DivisionID=2221&TeamID=6016&Section=Stats&PSORT=PTS&GSORT=GAA"
SELECTOR = 'div:contains("Skaters")'

# Colors
BLADES_OF_FURY_PINK = "#D54386"
BLADES_OF_FURY_TEAL = "#028680"

def find_skater_table():
  stats_page = http.get(BLADES_STATS_URL).body()
  parsed_html = html(stats_page)
  skaters_div = parsed_html.find(SELECTOR)
  return skaters_div.parents_until('table')

def convert_text_to_stat(text):
  splits = text.split('\n')

  stat_list = list()
  for i in range(0, len(splits)):
    stripped = splits[i].strip()
    if(len(stripped)):
      stat_list.append(stripped)

# number, name, gp, g, a, p, gpg, apg, ptpg, ppg, shg, pim
  stats = {
    "number": int(stat_list[0]),
    "player": stat_list[1].replace('\u00a0', " ").split(" ")[1],
    "gp": int(stat_list[2]),
    "g": int(stat_list[3]),
    "a": int(stat_list[4]),
    "p": int(stat_list[5]),
    "gpg": float(stat_list[6]),
    "apg": float(stat_list[7]),
    "ptpg": float(stat_list[8]),
    "ppg": int(stat_list[9]),
    "shg": int(stat_list[10]),
    "pim": int(stat_list[11]),
  }

  return stats

def extract_stats_from_table(table):
  player_stats = list()

  table_rows = table.find('tr')
  for i in range(2, table_rows.len()):
    player_text = table_rows.eq(i).text()
    player_stat = convert_text_to_stat(player_text)
    player_stats.append(player_stat)

  return player_stats

def render_stat_row(player_stats, stat):
  return render.Row(
    children = [
        render.Box(
          width = 12,
          height = 8,
          color = BLADES_OF_FURY_PINK,
          child = render.Text(
            "{}".format(player_stats["number"]),
            font = "tom-thumb",
          ),
        ),
        render.Box(
          height = 8,
          width = 40,
          child = render.Marquee(
            width = 40,
            align = "center",
            child=render.Text(
              "{}".format(player_stats["player"]),
              color = "#FF0",
              font = "tom-thumb",
            ),
          ),
        ),
        render.Box(
          height = 8,
          width = 12,
          child = render.Text(
            "{}".format(player_stats[stat]),
            color = "#FF0",
            font = "tom-thumb",
          ),
        ),
    ],
  )

def render_stat_view(title, player_stats, stat):
  sorted_indices = list()
  for i in range(0, len(player_stats)):
    if not len(sorted_indices):
      sorted_indices.append(i)
    else:
      for j in range(0, len(sorted_indices) + 1):
        reached_end = j + 1 > len(sorted_indices)

        if (reached_end):
          sorted_indices.append(i)
          break

        current_stat = player_stats[i][stat]
        compare_stat = player_stats[sorted_indices[j]][stat]
        
        if current_stat <= compare_stat:
          continue
        else:
          sorted_indices.insert(j, i)
          break

  return render.Column(
    children=[
      render.Box(
        height = 8,
        width = 64,
        color = BLADES_OF_FURY_TEAL,
        child = render.Text(
          title,
        ),
      ),
      render_stat_row(player_stats[sorted_indices[0]], stat),
      render_stat_row(player_stats[sorted_indices[1]], stat),
      render_stat_row(player_stats[sorted_indices[2]], stat),
      
    ]
  )

def main(config):
  cached_player_stats = cache.get("player_stats")
  if cached_player_stats == None:
    table = find_skater_table()
    player_stats = extract_stats_from_table(table)
    cache.set("player_stats", str(player_stats), ttl_seconds=10800)
  else:
    player_stats = json.decode(cached_player_stats)

  return render.Root(
        delay = 2000,
        child = render.Animation(
          children = [
            render_stat_view("Pts Leaders", player_stats, "p"),
            render_stat_view("Goal Leaders", player_stats, "g"),
            render_stat_view("Assist Leaders", player_stats, "a"),
            render_stat_view("PIM Leaders", player_stats, "pim"),
          ],
        )
  )
