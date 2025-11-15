(:spec "Role-Playing Game"
 :app-name "rpg"
 :models
       ((:model-name "Role"
         :fields (("name" ("CharField" "max_length" "12" "help_text" "Name (up to 12 characters)")))
         :ordering "['name']"
         :str "self.name")

        (:model-name "Kingdom"
         :fields (("name" ("CharField" "max_length" "8" "help_text" "Name (up to 8 characters)")))
         :ordering "['name']"
         :str "self.name")

        (:model-name "Character"
         :fields (("name" ("CharField" "max_length" "4" "help_text" "Hero's name (up to 4 characters)"))
                  ("hp" ("IntegerField" "help_text" "Hit Points"))
                  ("role" ("ForeignKey" "to" "Role" "on_delete" "CASCADE" "help_text" "Role"))
                  ("home" ("ForeignKey" "to" "Kingdom" "on_delete" "CASCADE" "help_text" "Kingdom")))
         :ordering "['name']"
         :str "self.name")))
