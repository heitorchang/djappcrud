(:spec "Role-Playing Game"
 :app-name "rpg"
 :models
       ((:model-name "Role"
         :fields (("name" ("CharField" "max_length" "6")))
         :ordering "['name']"
         :str "self.name")

        (:model-name "Kingdom"
         :fields (("name" ("CharField" "max_length" "8")))
         :ordering "['name']"
         :str "self.name")

        (:model-name "Character"
         :fields (("name" ("CharField" "max_length" "4"))
                  ("hp" ("IntegerField"))
                  ("role" ("ForeignKey" "to" "Role" "on_delete" "CASCADE"))
                  ("home" ("ForeignKey" "to" "Kingdom" "on_delete" "CASCADE")))
         :ordering "['name']"
         :str "self.name")))
