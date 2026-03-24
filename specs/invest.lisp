(:spec "Investments"
       :app-name "invest"

       :models
       ((:model-name "Broker"
                     :fields (("name" ("CharField" "max_length" "80" "help_text" "Broker's name")))
                     :ordering "['name']"
                     :str "self.name")

        (:model-name "Action"
                     :fields (("name" ("CharField" "max_length" "32" "help_text" "Type of action")))
                     :ordering "['name']"
                     :str "self.name")

        (:model-name "Investment"
                     :fields (("date" ("DateField" "default" "date.today" "help_text" "Date of investment"))
                              ("broker" ("ForeignKey" "to" "Broker" "on_delete" "CASCADE" "help_text" "Broker"))
                              ("action" ("ForeignKey" "to" "Action" "on_delete" "CASCADE" "help_text" "Action"))
                              ("instrument" ("CharField" "max_length" "200" "help_text" "Description of investment"))
                              ("quantity" ("DecimalField" "decimal_places" "3" "max_digits" "12" "help_text" "Quantity"))
                              ("unit_price" ("DecimalField" "decimal_places" "2" "max_digits" "12" "help_text" "Unit price"))
                              ("fees" ("DecimalField" "decimal_places" "2" "max_digits" "12" "help_text" "Fees"))
                              ("notes" ("TextField" "blank" "True" "help_text" "Notes")))
                     :ordering "['-date', 'instrument']"
                     :str "self.date.strftime('%Y-%m-%d') + ' ' + self.broker.name + ' ' + self.action.name + ' ' + self.instrument + ' x' + str(self.quantity)")))
