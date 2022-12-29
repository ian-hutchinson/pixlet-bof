load("render.star", "render")
load("http.star", "http")
load("html.star", "html")

BLADES_HOME_URL = "http://stats.nchl.com/site/3333/page.asp?Site=9818&page=Teams&LeagueID=9818&SeasonID=40&DivisionID=2221&TeamID=6016&Section=Home"

#TODO: These have been hacked in for now - opponent name:url mapping should live in a dictionary
#      Also, move the images to this repo
BOF_IMAGE_URL = "https://github.com/ian-hutchinson/pixlet-resources/blob/main/bof_100x.png?raw=true"
BADGER_BATTALION_IMAGE_URL = "https://github.com/ian-hutchinson/pixlet-resources/blob/main/bb.png?raw=true"

SELECTOR = 'span:contains("Next")'
PREVIOUS_GAME_SELECTOR = 'span:contains("Previous")'

# Colors
BLADES_OF_FURY_PINK = "#D54386"
BLADES_OF_FURY_TEAL = "#028680"

def extract_date_and_time_from_table(table):
  table_rows = table.find('tr')
  spans = table_rows.eq(1).find('span')
  date = spans.eq(0).text()
  time_and_location = spans.eq(1).text()

  time_and_location_split = time_and_location.split('\n')
  pm_index = time_and_location_split[1].find("PM")
  time = time_and_location_split[1][0:pm_index + 2].strip()
  
  return { "date": date, "time": time }

def find_next_game_table():
  stats_page = http.get(BLADES_HOME_URL).body()
  parsed_html = html(stats_page)
  next_game_div = parsed_html.find(SELECTOR)
  return next_game_div.parents_until('table')

def main(config):
  table = find_next_game_table()
  
  previous_game_span = table.find(PREVIOUS_GAME_SELECTOR)
  previous_game_table = previous_game_span.parents_until('table')
  previous_game_table_spans = previous_game_table.find('span')
  previous_game_table_rows = previous_game_table.find('tr')

  previous_game_header_text = previous_game_table_spans.eq(0).text().strip()
  vs_index = previous_game_header_text.find("vs")
  colon_index = previous_game_header_text.find(":")
  opposing_team_name = previous_game_header_text[vs_index + 3:colon_index]
  print(opposing_team_name)

  previous_game_table_data = previous_game_table_rows.eq(1).find('td')

  previous_game_date = previous_game_table_data.eq(0).text().strip()
  previous_game_home_team = previous_game_table_data.eq(2).text().strip()
  previous_game_home_score = previous_game_table_data.eq(3).text().strip()
  previous_game_road_team = previous_game_table_data.eq(5).text().strip()
  previous_game_road_score = previous_game_table_data.eq(6).text().strip()
  
  date_time = extract_date_and_time_from_table(table)

  bof_logo = http.get(BOF_IMAGE_URL).body()
  bb_logo = http.get(BADGER_BATTALION_IMAGE_URL).body()
  
  header = render.Column(
    children=[
      render.Row(
        children = [
          render.Box(
            height = 24,
            width = 24,
            child = render.Image(
              src = bof_logo,
              width = 24,
              height = 24
            )
          ),
          render.Box(
            height = 24,
            width = 16,
            # color = "#FFF"
            child = render.Text("VS")
          ),
          render.Box(
            height = 24,
            width = 24,
            child = render.Image(
              src = bb_logo,
              width = 24,
              height = 24
            )
          ),
        ],
      ),
      render.Row(
        children = [
          render.Box(
            height = 8,
            width = 64,
            child = render.Marquee(
              width = 64,
              offset_start = 0,
              child = render.Text(
                "{} @ {} vs {}".format(date_time["date"], date_time["time"], opposing_team_name),
                font = "tom-thumb",
                color = "#FF0",
              )
            )
          ),
        ],
      ),
    ]
  )

  return render.Root(
        delay = 50,
        child = header,
  )
