(:spec "Role-Playing Game"
 :app-name "rpg"
 :models
       ((:model-name "Role"
         :fields (("name" ("CharField" "max_length" "50")))
         :ordering "['name']"
         :str "self.name")

        (:model-name "Kingdom"
         :fields (("name" ("CharField" "max_length" "50")))
         :ordering "['name']"
         :str "self.name")

        (:model-name "Character"
         :fields (("name" ("CharField" "max_length" "50"))
                  ("hp" ("IntegerField"))
                  ("role" ("ForeignKey" "to" "Role" "on_delete" "CASCADE"))
                  ("home" ("ForeignKey" "to" "Kingdom" "on_delete" "CASCADE")))
         :ordering "['name']"
         :str "self.name")))
