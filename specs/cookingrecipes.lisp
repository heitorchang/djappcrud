(:spec "Cooking Recipes"
 :app-name "cookingrecipes"

 :models
       ((:model-name "Recipe"
         :fields (("title" ("CharField" "max_length" "200" "help_text" "'Recipe name'"))
                  ("description" ("CharField" "max_length" "300" "help_text" "'Brief description'"))
                  ("ingredients" ("TextField" "max_length" "5000" "help_text" "'Ingredients'"))
                  ("procedure" ("TextField" "max_length" "5000" "help_text" "'Procedure'")))
         :ordering "['title']"
         :str "self.title")))
