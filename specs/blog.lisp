(:spec "Blog with a single model"
 :app-name "blog"

 :models
 ((:model-name "Entry"
   :fields (("created_at" ("DateTimeField" "default" "datetime.now" "help_text" "'When file was created'"))
            ("subject" ("CharField" "max_length" "50" "help_text" "'Broad subject'"))
            ("title" ("CharField" "max_length" "150" "help_text" "'Post title'"))
            ("body" ("TextField" "help_text" "'The post body'")))

   :ordering "['-created_at']"
   :str "f'{self.created_at.strftime('%Y-%m-%d')} {self.title}'")))
