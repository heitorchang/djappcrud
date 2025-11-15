(:spec "Recipe Book"
       :app-name "recipebook"
       :models
       ((:model-name "Recipe"
                     :fields (("name" ("CharField" "max_length" "200" "help_text" "Recipe name"))
                              ("description" ("TextField" "help_text" "Description"))
                              ("ingredients" ("TextField" "help_text" "Ingredients"))
                              ("procedure" ("TextField" "help_text" "Procedure")))
                     :ordering "['name']"
                     :str "self.name")))
