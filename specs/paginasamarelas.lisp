(:spec "Páginas Amarelas"
 :app-name "paginasamarelas"
 :models
       ((:model-name "Categoria"
         :fields (("nome" ("CharField" "max_length" "80" "help_text" "'Nome da categoria'")))
         :ordering "['nome']"
         :str "self.nome")
        (:model-name "Empresa"
         :fields (("nome" ("CharField" "max_length" "80" "help_text" "'Nome da empresa'"))
                  ("categoria" ("ForeignKey" "to" "Categoria" "on_delete" "CASCADE" "help_text" "'Categoria da empresa'"))
                  ("endereco" ("CharField" "max_length" "200" "help_text" "'Endereço'"))
                  ("horario" ("CharField" "max_length" "200" "help_text" "'Horário de atendimento'"))
                  ("telefone" ("CharField" "max_length" "80" "help_text" "'Telefone fixo'"))
                  ("whatsapp" ("CharField" "max_length" "32" "help_text" "'Número de WhatsApp'"))
                  ("website" ("CharField" "max_length" "32" "help_text" "'Website'"))
                  ("descricao" ("TextField" "help_text" "'Descrição'")))
         :ordering "['nome']"
         :str "self.nome")))
