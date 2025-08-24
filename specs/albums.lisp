(:spec "Music albums"
 :app-name "albums"

 :models
       ((:model-name "Artist"
         :fields (("name" ("CharField" "max_length" "80" "help_text" "'Name of artist'"))
                  ("photo" ("ImageField" "help_text" "'Photo of artist'")))
         :ordering "['name']"
         :str "self.name")

        (:model-name "Album"
         :fields (("name" ("CharField" "max_length" "80" "help_text" "'Name of album'"))
                  ("artist" ("ForeignKey" "to" "Artist" "on_delete" "CASCADE" "null" "True" "help_text" "'Artist'"))
                  ("rating" ("IntegerField" "help_text" "'Rating (1-10)'"))
                  ("photo" ("ImageField" "help_text" "'Album cover'")))
         :ordering "['-rating', 'name']"
         :str "self.name")))
