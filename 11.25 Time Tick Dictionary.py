"""
Time Tick Dictionary
Anna Hughes hoge
CS 701
November 25th, 2018
"""

#each tick is 1 hour

time_tick_dict = {}

weeks = ["1", "2", "3", "4"]

days = ["sun", "mon", "tues", "wed", "thurs", "fri", "sat"]

hours = [str(i) for i in range(0, 24)]
for i in range(len(hours)):
    if len(hours[i]) != 2:
        hours[i] = "0" + hours[i]
        
#minutes = ["00", "15", "30", "45"]
#minutes = ["00", "05", "10", "15", "20", "25", "30", "35", "40", "45", "50", "55"]
        

tick = 0

for week in weeks:
    for day in days:
        for hour in hours:
            time = "%s.%s.%s" % (week, day, hour)
            time_tick_dict[time] = tick
        
            tick += 1
                
def t(time):
    return time_tick_dict[time]
          
#def leave(time):
#    """Leave 15 minutes/3 ticks before class starts."""
#    return time_tick_dict[time] - 3