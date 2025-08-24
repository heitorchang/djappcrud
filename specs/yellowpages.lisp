(:spec "Yellow Pages"
 :app-name "yellowpages"
 :models
       ((:model-name "Category"
         :fields (("name" ("CharField" "max_length" "80" "help_text" "'Category name'")))
         :ordering "['name']"
         :str "self.name")
        (:model-name "Company"
         :fields (("name" ("CharField" "max_length" "80" "help_text" "'Company name'"))
                  ("category" ("ForeignKey" "to" "Category" "on_delete" "CASCADE" "help_text" "'Category it belongs to'"))
                  ("address" ("CharField" "max_length" "200" "help_text" "'Address'"))
                  ("opening_hours" ("CharField" "max_length" "200" "help_text" "'Opening hours'"))
                  ("phone" ("CharField" "max_length" "80" "help_text" "'Phone'"))
                  ("whatsapp" ("CharField" "max_length" "32" "help_text" "'WhatsApp number'"))
                  ("website" ("CharField" "max_length" "32" "help_text" "'Site link'"))
                  ("description" ("TextField" "help_text" "'Description'")))
         :ordering "['name']"
         :str "self.name")))
