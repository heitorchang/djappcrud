(:spec "Blog with a single model"
 :app-name "blog"

 :models
 ((:model-name "Entry"
   :fields (("user" ("ForeignKey" "to" "get_user_model()" "on_delete" "models.CASCADE"))
            ("created_at" ("DateTimeField" "default" "datetime.datetime.now"))
            ("title" ("CharField" "max_length" "150")))

   :ordering "['-created_at']"
   :str "{self.created_at.strftime('%Y-%m-%d')} {self.title}")))
