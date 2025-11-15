(:spec "Food Diary"
 :app-name "fooddiary"

 :models
       ((:model-name "Entry"
         :fields (("when" ("DateField" "help_text" "'Date to record'"))
                  ("breakfast" ("CharField" "max_length" "50" "help_text" "'Breakfast'"))
                  ("lunch" ("CharField" "max_length" "50" "help_text" "'Lunch'"))
                  ("snack" ("CharField" "max_length" "50" "help_text" "'Snack'"))
                  ("dinner" ("CharField" "max_length" "50" "help_text" "'Dinner'")))
         :ordering "['-when']"
         :str "f\"{self.when.strftime('%Y-%m-%d')}\"")))
