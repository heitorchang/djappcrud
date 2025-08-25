(:spec "Job (hunt) diary"
 :app-name "jobdiary"

 :models
       ((:model-name "JobBoard"
         :fields (("name" ("CharField" "max_length" "80" "help_text" "'Job board name'"))
                  ("url" ("CharField" "max_length" "100" "help_text" "'Job board website'")))
         :ordering "['name']"
         :str "self.name")

        (:model-name "VisitEntry"
         :fields (("job_board" ("ForeignKey" "to" "JobBoard" "on_delete" "CASCADE" "help_text" "'Job board visited'"))
                  ("when" ("DateField" "help_text" "'When visited'"))
                  ("report" ("CharField" "max_length" "200" "help_text" "'What happened?'"))
                  ("experience_rating" ("IntegerField" "help_text" "'Experience rating (1-10)'")))
         :ordering "['-when', 'job_board']"
         :str "f'{self.when}: [{self.job_board}] {self.report[:80]}... ({self.experience_rating})'")

        (:model-name "DailyEntry"
         :fields (("when" ("DateField" "help_text" "'Date'"))
                  ("report" ("TextField" "max_length" "5000" "help_text" "'Daily report'"))
                  ("experience_rating" ("IntegerField" "help_text" "'Experience rating (1-10)'")))
         :ordering "['-when']"
         :str "f'{self.when.isoformat()} {self.report[:150]}... ({self.experience_rating})'")))
