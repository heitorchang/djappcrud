(:spec "Books"
 :app-name "books"

 :models
       ((:model-name "Author"
         :fields (("name" ("CharField" "max_length" "80" "help_text" "'Name of author'"))
                  ("photo" ("ImageField" "help_text" "'Photo of author'")))
         :ordering "['name']"
         :str "self.name")

        (:model-name "Book"
         :fields (("name" ("CharField" "max_length" "80" "help_text" "'Name of book'"))
                  ("author" ("ForeignKey" "to" "Author" "on_delete" "CASCADE" "null" "True" "help_text" "'Artist'"))
                  ("stars" ("IntegerField" "help_text" "'Stars (1 to 5)'"))
                  ("photo" ("ImageField" "help_text" "'Book cover'")))
         :ordering "['-stars', 'name']"
         :str "self.name")))
