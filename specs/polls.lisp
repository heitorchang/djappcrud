(:spec "Official tutorial models"
 :app-name "polls"

 :models
       ((:model-name "Question"
         :fields (("question_text" ("CharField" "max_length" "200" "help_text" "'Question text'"))
                  ("pub_date" ("DateTimeField" "help_text" "'date published'")))
         :ordering "['-pub_date']"
         :str "self.question_text")

        (:model-name "Choice"
         :fields (("question" ("ForeignKey" "to" "Question" "on_delete" "CASCADE" "help_text" "'Related Question'"))
                  ("choice_text" ("CharField" "max_length" "200" "help_text" "'Choice Text'"))
                  ("votes" ("IntegerField" "default" "0" "help_text" "'Number of votes'")))
         :ordering "['question', 'choice_text']"
                     :str "f'{self.question} {self.choice_text}'")))
