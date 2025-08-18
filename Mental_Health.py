    import pandas as pd
>>> import numpy as np
>>> import seaborn as sns
>>> import matplotlib.pyplot as plt
>>> mental_health = pd.read_csv("C:/Users/jsimo/OneDrive/Desktop/Datasets/mental_health.csv")
>>> print(mental_health)
>>> mental_health.columns
>>> us_mental_health = mental_health[mental_health["Country"] == "United States"]
>>> us_mental_health = us_mental_health.rename(columns={"self_employed":"Self Employed","treatment":"Treatment","mental_health_interview":"Mental Health Interview","family_history":"Family History","Days_Indoors":"Days Indoors","Growing_Stress":"Growing Stress","Change\es_Habits":"Change in Habits","Mental_Health_History":"Histos_Habits":"Change in Habits","Mental_Health_History":"History of Mental Health","Mood_Swings":"Mood Swings","Coping_Struggles":"Coping Struggles","Work_Interest":"Interest in Work","Social_Weakness":"Social Weakness","care_options":"Care Options"})
>>> us_mental_health = us_mental_health.drop('Timestamp',axis=1)
>>> us_mental_health = us_mental_health.dropna()
>>> us_mental_health.groupby("Gender")[["Mood Swings","History of Mental Health"]].value_counts()
>>> ax = sns.countplot(x="History of Mental Health",hue="Gender",data=us_mental_health)
>>> ax.set_title('History of Mental Health by Gender')
Text(0.5, 1.0, 'History of Mental Health by Gender')
>>> ax.set_xlabel('Gender')
Text(0.5, 0, 'Gender')
>>> plt.show()
