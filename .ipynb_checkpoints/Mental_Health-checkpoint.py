    import pandas as pd
>>> import numpy as np
>>> import seaborn as sns
>>> import matplotlib.pyplot as plt
>>> mental_health = pd.read_csv("C:/Users/jsimo/OneDrive/Desktop/Datasets/mental_health.csv")
>>> print(mental_health)
              Timestamp  Gender        Country Occupation self_employed family_history treatment Days_Indoors Growing_Stress Changes_Habits Mental_Health_History Mood_Swings Coping_Struggles Work_Interest Social_Weakness mental_health_interview care_options
0       8/27/2014 11:29  Female  United States  Corporate           NaN             No       Yes    1-14 days            Yes             No                   Yes      Medium               No            No             Yes                      No     Not sure
1       8/27/2014 11:31  Female  United States  Corporate           NaN            Yes       Yes    1-14 days            Yes             No                   Yes      Medium               No            No             Yes                      No           No
2       8/27/2014 11:32  Female  United States  Corporate           NaN            Yes       Yes    1-14 days            Yes             No                   Yes      Medium               No            No             Yes                      No          Yes
3       8/27/2014 11:37  Female  United States  Corporate            No            Yes       Yes    1-14 days            Yes             No                   Yes      Medium               No            No             Yes                   Maybe          Yes
4       8/27/2014 11:43  Female  United States  Corporate            No            Yes       Yes    1-14 days            Yes             No                   Yes      Medium               No            No             Yes                      No          Yes
...                 ...     ...            ...        ...           ...            ...       ...          ...            ...            ...                   ...         ...              ...           ...             ...                     ...          ...
292359  7/27/2015 23:25    Male  United States   Business           Yes            Yes       Yes   15-30 days             No          Maybe                    No         Low              Yes            No           Maybe                   Maybe     Not sure
292360   8/17/2015 9:38    Male   South Africa   Business            No            Yes       Yes   15-30 days             No          Maybe                    No         Low              Yes            No           Maybe                      No          Yes
292361  8/25/2015 19:59    Male  United States   Business            No            Yes        No   15-30 days             No          Maybe                    No         Low              Yes            No           Maybe                      No           No
292362   9/26/2015 1:07    Male  United States   Business            No            Yes       Yes   15-30 days             No          Maybe                    No         Low              Yes            No           Maybe                      No          Yes
292363   2/1/2016 23:04    Male  United States   Business            No            Yes       Yes   15-30 days             No          Maybe                    No         Low              Yes            No           Maybe                      No          Yes

[292364 rows x 17 columns]
>>> mental_health.columns
Index(['Timestamp', 'Gender', 'Country', 'Occupation', 'self_employed',
       'family_history', 'treatment', 'Days_Indoors', 'Growing_Stress',
       'Changes_Habits', 'Mental_Health_History', 'Mood_Swings',
       'Coping_Struggles', 'Work_Interest', 'Social_Weakness',
       'mental_health_interview', 'care_options'],
      dtype='object')
>>> us_mental_health = mental_health[mental_health["Country"] == "United States"]
>>> us_mental_health = us_mental_health.rename(columns={"self_employed":"Self Employed","treatment":"Treatment","mental_health_interview":"Mental Health Interview","family_history":"Family History","Days_Indoors":"Days Indoors","Growing_Stress":"Growing Stress","Change\es_Habits":"Change in Habits","Mental_Health_History":"Histos_Habits":"Change in Habits","Mental_Health_History":"History of Mental Health","Mood_Swings":"Mood Swings","Coping_Struggles":"Coping Struggles","Work_Interest":"Interest in Work","Social_Weakness":"Social Weakness","care_options":"Care Options"})
>>> us_mental_health
              Timestamp  Gender        Country Occupation Self Employed Family History Treatment Days Indoors Growing Stress Change in Habits History of Mental Health Mood Swings Coping Struggles Interest in Work Social Weakness Mental Health Interview Care Options
0       8/27/2014 11:29  Female  United States  Corporate           NaN             No       Yes    1-14 days            Yes               No                      Yes      Medium               No               No             Yes                      No     Not sure
1       8/27/2014 11:31  Female  United States  Corporate           NaN            Yes       Yes    1-14 days            Yes               No                      Yes      Medium               No               No             Yes                      No           No
2       8/27/2014 11:32  Female  United States  Corporate           NaN            Yes       Yes    1-14 days            Yes               No                      Yes      Medium               No               No             Yes                      No          Yes
3       8/27/2014 11:37  Female  United States  Corporate            No            Yes       Yes    1-14 days            Yes               No                      Yes      Medium               No               No             Yes                   Maybe          Yes
4       8/27/2014 11:43  Female  United States  Corporate            No            Yes       Yes    1-14 days            Yes               No                      Yes      Medium               No               No             Yes                      No          Yes
...                 ...     ...            ...        ...           ...            ...       ...          ...            ...              ...                      ...         ...              ...              ...             ...                     ...          ...
292358   5/6/2015 16:55    Male  United States   Business            No             No        No   15-30 days             No            Maybe                       No         Low              Yes               No           Maybe                   Maybe     Not sure
292359  7/27/2015 23:25    Male  United States   Business           Yes            Yes       Yes   15-30 days             No            Maybe                       No         Low              Yes               No           Maybe                   Maybe     Not sure
292361  8/25/2015 19:59    Male  United States   Business            No            Yes        No   15-30 days             No            Maybe                       No         Low              Yes               No           Maybe                      No           No
292362   9/26/2015 1:07    Male  United States   Business            No            Yes       Yes   15-30 days             No            Maybe                       No         Low              Yes               No           Maybe                      No          Yes
292363   2/1/2016 23:04    Male  United States   Business            No            Yes       Yes   15-30 days             No            Maybe                       No         Low              Yes               No           Maybe                      No          Yes

[171308 rows x 17 columns]
>>> us_mental_health = us_mental_health.drop('Timestamp',axis=1)
>>> us_mental_health = us_mental_health.dropna()
>>> us_mental_health.groupby("Gender")[["Mood Swings","History of Mental Health"]].value_counts()
Gender  Mood Swings  History of Mental Health
Female  High         Maybe                        4503
        Low          Maybe                        4345
                     No                           3950
        Medium       No                           3871
                     Yes                          3871
                     Maybe                        3634
        High         Yes                          3555
                     No                           3476
        Low          Yes                          3081
Male    Low          Maybe                       17150
        Medium       No                          17150
                     Yes                         17150
        Low          No                          16121
        High         No                          15092
                     Maybe                       13034
                     Yes                         13034
        Low          Yes                         12691
        Medium       Maybe                       12348
Name: count, dtype: int64
>>> ax = sns.countplot(x="History of Mental Health",hue="Gender",data=us_mental_health)
>>> ax.set_title('History of Mental Health by Gender')
Text(0.5, 1.0, 'History of Mental Health by Gender')
>>> ax.set_xlabel('Gender')
Text(0.5, 0, 'Gender')
>>> plt.show()
