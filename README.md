# NubankPBI
Acesse suas informações da sua conta do Nubank utilizando o Power BI
<br>
Se quiser tirar alguma dúvida pode me chamar no Linkedin https://www.linkedin.com/in/tadeu-mansi/

## Agradecimentos
Agradeço imensamente o @https://github.com/andreroggeri, por ter criado e mantido a biblioteca pynubank (responsável por se conectar nas apis oficiais do Banco), além de me ajudar muito tirando todas as minhas dúvidas, se puder confira a biblioteca, e se conseguir contribua com o projeto https://github.com/andreroggeri/pynubank

## Atenção !
O Nubank pode bloquear a sua conta por 72 horas caso detecte algum comportamento anormal !
Por conta disso, evite enviar muitas requisições. (Por conta disso a preferência em utilizar o Jupyter Notebook)
## Arquitetura
![Image 5](https://github.com/3t1n/NubankPBI/blob/master/Imagens/Nubank.png)

Pesquisando na internet encontrei a biblioteca PyNubank que se conectava nas apis oficiais do Nubank, utilizando Python para se autenticar e retornar os resultados, ela é bem simples de entender e cumpre bem o seu papel. Utilizei ela para pegar os dados e carregar em um banco de dados MySQL local, que possuo instalado em minha máquina, para conseguir ter um histórico e para não precisar ficar chamando toda hora a api do Nubank, depois utilizei o Power BI para ler os dados do MySQL e criar as visões que me auxiliassem no meu controle financeiro.

## Pré Requisitos

Tenha instalado em sua máquina o Banco de Dados MySQL, caso não possua você pode fazer o download do Banco completo nesse Link: https://dev.mysql.com/downloads/installer/
ou se preferir baixar uma versão mais leve baixe o XAMPP,
<br>nesse link: https://www.apachefriends.org/pt_br/index.html.
<br>
Para rodar o script python estou usando o Jupyter Notebook com o ambiente do Anaconda, link para fazer o download: https://www.anaconda.com/products/individual

## Passo a Passo

Após instalar todos os softwares, abra o arquivo ETL_NUBANK.ipynb no Jupyter e execute a primeira célula para instalar as dependências 
<br>
`pip install mysql-connector`
<br>
`pip install pynubank`
<br>

### Configurar Conexão com o Nubank
Para se conectar no nubank será necessário autorizar a conexão lendo o qrcode gerado no código pelo aplicativo do Nubank no Celular.

```python
from pynubank import Nubank

nu = Nubank()
uuid, qr_code = nu.get_qr_code()
qr_code.print_ascii(invert=True)
input('Após escanear o QRCode pressione enter para continuar')
# Nesse momento será printado o QRCode no console
# Você precisa escanear pelo o seu app do celular
# Esse menu fica em NU > Perfil > Acesso pelo site
# Após a leitura do qrcode execute essa linha
nu.authenticate_with_qr_code('CPF', 'SENHA', uuid)
```
### Configurar Conexão com o MySQL
Para se conectar no Banco de dados, preencha as variáveis host,user e password respectivamente com o ip do seu servidor de banco de dados, o seu usuário e sua senha do banco de dados, para assim o python consiga se conectar no seu banco de dados e possa efetuar as consultas SQL.

```python
mydb = mysql.connector.connect(
  host="HOST",
  user="USER",
  password="SENHA"
)
cursor = mydb.cursor()
cursor = mydb.cursor(buffered=True)
```
### Cria a estrutura do Banco de Dados
Depois de realizar a conexão execute o bloco que cria o Database e as tabelas do Banco de Dados.

```python
#Cria a estrutura do banco
cursor.execute("CREATE DATABASE IF NOT EXISTS nubank;")
cursor.execute("USE nubank;")
cursor.execute( """CREATE TABLE IF NOT EXISTS `fatura_cartao` (
  `fatura_id` varchar(100) NOT NULL,
  `descricao` varchar(255) DEFAULT NULL,
  `categoria` varchar(100) DEFAULT NULL,
  `valor` decimal(13,2) DEFAULT NULL,
  `datetime` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `origem` varchar(100) DEFAULT NULL,
  `titulo` varchar(100) DEFAULT NULL,
  `conta` varchar(100) DEFAULT NULL,
  `lat` varchar(30) DEFAULT NULL,
  `lon` varchar(30) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`fatura_id`)
);""")
cursor.execute( """CREATE TABLE IF NOT EXISTS `conta_corrente` (
  `id` varchar(255) NOT NULL,
  `operacao` varchar(50) DEFAULT NULL,
  `titulo` varchar(50) DEFAULT NULL,
  `detalhe` varchar(255) DEFAULT NULL,
  `data` date DEFAULT NULL,
  `Valor` float DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
);""")
```
### Realiza a carga dos dados no Banco de Dados
Depois é só executar o bloco abaixo, que vai realizar a carga dos seus dados do Nubank no seu Banco de Dados
```python
card_statements = nu.get_card_statements()
account_statements = nu.get_account_statements()
#Faz a carga das transações do Cartão de Crédito
for idx,compra in enumerate(card_statements):
    cursor.execute("SELECT * FROM fatura_cartao WHERE fatura_id = %s",(compra['id'], ))
    if(cursor.rowcount == 0):
        print('Linha',idx,' Inserida')
        details = compra.get("details",None)
        if(details != None):
            long = details.get("lon", None)
            lat = details.get("lat", None)
        cursor.execute("INSERT INTO fatura_cartao VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s);",(compra['id'],compra['description'],compra['category'],compra['amount']/100,compra['time'],compra.get("source",None),compra['title'],compra.get("account",None),lat,long, datetime.datetime.now(), datetime.datetime.now()))
#Faz a carga das transações da Conta Corrente
for idx,t in enumerate(account_statements):
    if t['__typename'] == "TransferInEvent" :
        tipo_operacao = "Entrada"
        valor = t['amount']
    elif t['__typename'] == "TransferOutEvent" :
        tipo_operacao = "Saída"
        valor = t['amount'] * -1
    elif t['__typename'] == "TransferOutReversalEvent" :   
        tipo_operacao = "Devolução"
        valor = t['amount']
    elif t['__typename'] == "DebitPurchaseEvent" :
        tipo_operacao = "Compra no Débito"
        valor = t['amount'] * -1
    elif t['__typename'] == "BarcodePaymentEvent" :
        tipo_operacao = "Compra no Boleto"
        valor = t['amount'] * -1       
    elif t['__typename'] == "DebitWithdrawalFeeEvent" :
        tipo_operacao = "Tarifa de Saque"
        valor = t['amount'] * -1
    elif t['__typename'] == "DebitWithdrawalEvent" :
        tipo_operacao = "Saque"
        valor = t['amount'] * -1
    elif t['__typename'] == "BillPaymentEvent" :
        tipo_operacao = "Pagamento da Fatura do Cartão de Crédito"
        valor = float(t['detail'][19:].replace(".", "").replace(",", ".")) * -1
    else:
        valor = t['amount']   
    cursor.execute("SELECT * FROM conta_corrente WHERE id = %s",(t['id'], )) 
    if(cursor.rowcount == 0):
        print('Linha',idx,' Inserida')
        cursor.execute("INSERT INTO conta_corrente VALUES (%s,%s,%s,%s,%s,%s,%s,%s);",(t['id'],tipo_operacao,t['title'],t['detail'],t['postDate'],valor,datetime.datetime.now(), datetime.datetime.now()))
#Faz o commit de todas transações no Banco de Dados
mydb.commit()
```
## Configurando o Power BI
Após ter toda estrutura criada com os dados carregados, abra o arquivo Nubank.pbix, e clique em atualizar (Você vai perceber que na primeira vez o arquivo do Power BI vai estar vazio, após efetuar esses procedimentos seus dados serão carregados para o relatório)

![Image 1](https://github.com/3t1n/NubankPBI/blob/master/Imagens/1.JPG)

Após clicar em atualizar, essa tela será mostrada para você, nela você vai se autenticar com o seu Banco de Dados MySQL, selecione a opção de autenticação com o Banco de Dados.

![Image 2](https://github.com/3t1n/NubankPBI/blob/master/Imagens/2.JPG)

Insira as credenciais de acesso ao seu Banco de Dados.

![Image 3](https://github.com/3t1n/NubankPBI/blob/master/Imagens/3.JPG)

Espere as atualizações e o Power BI irá mostrar o relatório com os seus dados financeiros da sua conta do Nubank

![Image 4](https://github.com/3t1n/NubankPBI/blob/master/Imagens/4.JPG)

