(:spec "Alexie CRUD"
 :app-name "alexiecrud"

 :models
       ((:model-name "AccountType"
         :fields (("name" ("CharField" "max_length" "80" "help_text" "'Account type name'"))
                  ("sign" ("IntegerField" "help_text" "'+/-1, effect on debits'"))
                  ("order" ("IntegerField" "help_text" "'Sorting order'")))
         :ordering "['order']"
         :str "self.name")

        (:model-name "Account"
         :fields (("account_type" ("ForeignKey" "to" "AccountType" "on_delete" "CASCADE" "help_text" "'Account type'"))
                  ("name" ("CharField" "max_length" "80" "help_text" "'Account name'"))
                  ("balance" ("DecimalField" "max_digits" "22" "decimal_places" "2" "help_text" "'Total balance'")))
         :ordering "['name']"
         :str "self.name")

        (:model-name "Transaction"
         :fields (("created_at" ("DateField" "help_text" "'Transaction date'"))
                  ("description" ("CharField" "max_length" "200" "help_text" "'Description'"))
                  ("amount" ("DecimalField" "max_digits" "22" "decimal_places" "2" "help_text" "'Amount'"))
                  ("debit" ("ForeignKey" "to" "Account" "on_delete" "CASCADE" "related_name" "'debit_transactions'" "help_text" "'Debit account'"))
                  ("credit" ("ForeignKey" "to" "Account" "on_delete" "CASCADE" "related_name" "'credit_transactions'" "help_text" "'Credit account'")))
         :ordering "['-created_at', 'description']"
         :str "f'{self.created_at} {self.description}'")))
