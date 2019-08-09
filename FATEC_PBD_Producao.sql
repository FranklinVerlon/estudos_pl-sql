-- Script criacao Mat�ria Prima e Produ��o - REVIS�O PL/SQL Oracle
/* 
fabrica ( cod_fabrica, nome_fabr, fone_fabr, endere�o_fabr, cep_fabr)
produto ( cod_prod, nome_prod, peso_prod, preco_sugerido, tipo_prod ( Acabado ou Mat�ria Prima) )
prod_acabado ( cod_acabado(FK), qtde_estoque, preco_producao)  cod_acabado referencia cod_produto
prod_mater_prima (cod_mater_prima(FK) , tipo_mater_prima (Componente ou Semi-acabado), material ( se � pl�stico, a�o inoxid�vel, ferro, alum�nio, etc.) , unidade_medida ( m, kg, unidade), qtde_estoque, estoque_reposicao, preco_custo_unidade_medida) cod_mater_prima referencia cod_produto
ordem_producao ( num_ordem, cod_fabrica(fk), data_ordem, data_entrega, custo_total_producao) 
item_ordem (num_ordem(fk), cod_prod(fk), quantidade_solicitada, qtde_produzida, custo_total_producao_item)
composi��o_prod_acabado ( cod_acabado(FK), cod_mater_prima(FK), qtde_por_prod, observa��o)
*/
ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MM-YYYY HH24:MI:SS';
ALTER SESSION SET NLS_LANGUAGE = PORTUGUESE;
Alter Session Set NLS_language= 'BRAZILIAN PORTUGUESE';
SELECT SESSIONTIMEZONE, CURRENT_TIMESTAMP FROM DUAL;

-- limpeza das tabelas
DROP TABLE item_ordem CASCADE CONSTRAINTS PURGE;
DROP TABLE Ordem_Producao CASCADE CONSTRAINTS PURGE;
DROP TABLE Fabrica CASCADE CONSTRAINTS PURGE;
DROP TABLE composicao_prod_acabado CASCADE CONSTRAINTS PURGE;
DROP TABLE prod_mater_prima CASCADE CONSTRAINTS PURGE;
DROP TABLE prod_acabado CASCADE CONSTRAINTS PURGE;
DROP TABLE Produto CASCADE CONSTRAINTS PURGE;

CREATE TABLE Produto
(
	cod_prod             INTEGER NOT NULL ,
	nome_prod            VARCHAR2(30) NULL ,
	peso_prod            NUMBER(5,2) NULL ,
	preco_sugerido       NUMBER(10,2) NULL ,
	tipo_prod            VARCHAR2(30) NULL ,
CONSTRAINT  XPKProdutooc PRIMARY KEY (cod_prod));

ALTER TABLE produto ADD CHECK ( tipo_prod IN ( 'ACABADO', 'MATERIA PRIMA'));

INSERT INTO produto VALUES ( 1, 'Motor diesel 2.0', 250, 4500, 'ACABADO') ; 
INSERT INTO produto VALUES ( 2, 'Bloco Motor Diesel', 150, 2500, 'MATERIA PRIMA') ; 
INSERT INTO produto VALUES ( 3, 'Cabecote', 15, 300, 'MATERIA PRIMA') ; 
INSERT INTO produto VALUES ( 4, 'Pistao', 25, 400, 'MATERIA PRIMA') ; 
INSERT INTO produto VALUES ( 5, 'Biela', 15, 510, 'MATERIA PRIMA') ; 
INSERT INTO produto VALUES ( 6, 'Virabrequim', 25, 300, 'MATERIA PRIMA') ;
INSERT INTO produto VALUES ( 7, 'Aco Carbono', 20, 25, 'MATERIA PRIMA') ; 
INSERT INTO produto VALUES ( 8, 'Bronze', 15, 29, 'MATERIA PRIMA') ; 

INSERT INTO produto VALUES ( 9, 'Motor Eletrico 10HP', 250, 4500, 'ACABADO') ; 
INSERT INTO produto VALUES ( 10, 'Bloco Motor Eletrico', 150, 2500, 'MATERIA PRIMA') ; 
INSERT INTO produto VALUES ( 11, 'Rotor', 15, 300, 'MATERIA PRIMA') ; 
INSERT INTO produto VALUES ( 12, 'Eixo', 25, 400, 'MATERIA PRIMA') ; 
INSERT INTO produto VALUES ( 13, 'Rolamento', 15, 510, 'MATERIA PRIMA') ; 
INSERT INTO produto VALUES ( 14, 'Ventoinha', 25, 300, 'MATERIA PRIMA') ;
INSERT INTO produto VALUES ( 15, 'Ferro', 20, 25, 'MATERIA PRIMA') ; 
INSERT INTO produto VALUES ( 16, 'Cobre', 15, 29, 'MATERIA PRIMA') ;

SELECT * FROM produto ;

CREATE TABLE prod_acabado
(
	cod_acabado          INTEGER NOT NULL ,
	qtde_esqtoque        INTEGER NULL ,
	preco_producao       NUMBER(10,2) NULL ,
CONSTRAINT  XPKprod_acabadooc PRIMARY KEY (cod_acabado),
CONSTRAINT R_12oc FOREIGN KEY (cod_acabado) REFERENCES Produto (cod_prod));

INSERT INTO prod_acabado VALUES ( 1, 5, 2000) ;
INSERT INTO prod_acabado VALUES ( 9, 25, 2000) ;

CREATE TABLE prod_mater_prima
(
	cod_mater_prima      INTEGER NOT NULL ,
	tipo_mater_prima     VARCHAR2(30) NULL ,
	material             VARCHAR2(30) NULL ,
	unidade_medida       VARCHAR2(30) NULL ,
	qtde_estoque         INTEGER NULL ,
	estoque_reposicao    INTEGER NULL ,
	preco_custo_unidade_medida NUMBER(10,2) NULL ,
CONSTRAINT  XPKprod_mater_primaoc PRIMARY KEY (cod_mater_prima),
CONSTRAINT R_13oc FOREIGN KEY (cod_mater_prima) REFERENCES Produto (cod_prod));

delete from prod_mater_prima ;

ALTER TABLE prod_mater_prima ADD CHECK ( tipo_mater_prima IN ( 'COMPONENTE', 'SEMI-ACABADO')) ;

INSERT INTO prod_mater_prima VALUES ( 2, 'COMPONENTE', 'Aco', 'kg', 10, 5, 100) ; 
INSERT INTO prod_mater_prima VALUES ( 3, 'COMPONENTE', 'Aco', 'kg', 12,3,200) ; 
INSERT INTO prod_mater_prima VALUES ( 4, 'COMPONENTE', 'Aco', 'm', 7,2,300) ; 
INSERT INTO prod_mater_prima VALUES ( 5, 'COMPONENTE', 'Aco', 'm', 8, 3, 200) ; 
INSERT INTO prod_mater_prima VALUES ( 6, 'COMPONENTE', 'Aco', 'm', 11, 5, 189) ;
INSERT INTO prod_mater_prima VALUES ( 7, 'SEMI-ACABADO', 'Aco', 'kg', 7, 5, 101) ; 
INSERT INTO prod_mater_prima VALUES ( 8, 'SEMI-ACABADO', 'Bronze', 'kg', 18,4,79) ; 

SELECT * FROM prod_mater_prima ;

INSERT INTO prod_mater_prima VALUES ( 10, 'COMPONENTE', 'Ferro', 'kg', 10, 5, 100) ; 
INSERT INTO prod_mater_prima VALUES ( 11, 'COMPONENTE', 'Ferro', 'kg', 12,3,200) ; 
INSERT INTO prod_mater_prima VALUES ( 12, 'COMPONENTE', 'Ferro', 'm', 7,2,300) ; 
INSERT INTO prod_mater_prima VALUES ( 13, 'COMPONENTE', 'Ferro', 'm', 8, 3, 200) ; 
INSERT INTO prod_mater_prima VALUES ( 14, 'COMPONENTE', 'Plastico', 'm', 11, 5, 189) ;
INSERT INTO prod_mater_prima VALUES ( 15, 'SEMI-ACABADO', 'Ferro', 'kg', 17, 8, 121) ; 
INSERT INTO prod_mater_prima VALUES ( 16, 'SEMI-ACABADO', 'Cobre', 'kg', 17,8,79) ; 

SELECT * FROM prod_mater_prima ;

CREATE TABLE composicao_prod_acabado
(
	cod_acabado          INTEGER NOT NULL ,
	cod_mater_prima      INTEGER NOT NULL ,
	qtde_por_prod        INTEGER NULL ,
	observacao           VARCHAR2(30) NULL ,
CONSTRAINT  XPKcomposicao_prod_acabadooc PRIMARY KEY (cod_acabado,cod_mater_prima),
CONSTRAINT R_15oc FOREIGN KEY (cod_acabado) REFERENCES prod_acabado (cod_acabado),
CONSTRAINT R_16oc FOREIGN KEY (cod_mater_prima) REFERENCES prod_mater_prima (cod_mater_prima));

INSERT INTO composicao_prod_acabado VALUES ( 1, 2, 1, null);
INSERT INTO composicao_prod_acabado VALUES ( 1, 3, 4, null);
INSERT INTO composicao_prod_acabado VALUES ( 1, 4, 4, null);
INSERT INTO composicao_prod_acabado VALUES ( 1, 5, 4, null);
INSERT INTO composicao_prod_acabado VALUES ( 1, 6, 4, null);

INSERT INTO composicao_prod_acabado VALUES ( 9, 10, 1, null);
INSERT INTO composicao_prod_acabado VALUES ( 9, 11, 1, null);
INSERT INTO composicao_prod_acabado VALUES ( 9, 12, 1, null);
INSERT INTO composicao_prod_acabado VALUES ( 9, 13, 4, null);
INSERT INTO composicao_prod_acabado VALUES ( 9, 14, 1, null);

SELECT * FROM composicao_prod_acabado ;

CREATE TABLE Fabrica
(
	cod_fabrica          INTEGER NOT NULL ,
	nome_fabr            VARCHAR2(30) NULL ,
	endereco_fabr        VARCHAR2(30) NULL ,
	fone_fabr            VARCHAR2(30) NULL ,
	cep_fabr             VARCHAR2(30) NULL ,
CONSTRAINT  XPKFabricaoc PRIMARY KEY (cod_fabrica));

INSERT INTO fabrica VALUES ( 100, 'ABC Fabril', 'Rua Azul', '1155446677', '01040-050') ;
INSERT INTO fabrica VALUES ( 200, 'Iron Industria', 'Rua Verde', '1155876577', '01030-050') ;

CREATE TABLE Ordem_Producao
(
	Num_ordem            INTEGER NOT NULL ,
	data_ordem           TIMESTAMP NULL ,
	data_entrega         TIMESTAMP NULL ,
	custo_total_producao NUMBER(10,2) NULL ,
	cod_fabrica          INTEGER NULL ,
CONSTRAINT  XPKOrdem_Producaooc PRIMARY KEY (Num_ordem),
CONSTRAINT R_1oc FOREIGN KEY (cod_fabrica) REFERENCES Fabrica (cod_fabrica) ON DELETE SET NULL);

DROP SEQUENCE op_seq;
CREATE SEQUENCE  op_seq START WITH 1000 ;

INSERT INTO ordem_producao VALUES ( op_seq.nextval, current_timestamp - 5, null, 0, 100) ;
INSERT INTO ordem_producao VALUES ( op_seq.nextval, current_timestamp - 3, null, 0, 200) ;

CREATE TABLE item_ordem
(
	Num_ordem            INTEGER NOT NULL ,
	cod_prod             INTEGER NOT NULL ,
	quantidade_produzida INTEGER NULL ,
	custo_total_producao_item NUMBER(10,2) NULL ,
	quantidade_solicitada INTEGER NULL ,
CONSTRAINT  XPKitem_ordemoc PRIMARY KEY (Num_ordem,cod_prod),
CONSTRAINT R_2oc FOREIGN KEY (Num_ordem) REFERENCES Ordem_Producao (Num_ordem),
CONSTRAINT R_10oc FOREIGN KEY (cod_prod) REFERENCES Produto (cod_prod));

INSERT INTO Item_ordem VALUES ( 1000, 1,  0, null , 2) ;
INSERT INTO Item_ordem VALUES ( 1000, 9,  0, null , 3) ;
INSERT INTO Item_ordem VALUES ( 1001, 1,  0, null , 1) ;
INSERT INTO Item_ordem VALUES ( 1001, 9,  0, null , 1) ;

SELECT * FROM ordem_producao ;
SELECT * FROM Produto ;
SELECT * FROM item_ordem ;


/*******************************************************************************************************************
-- AULA_1 02_DE_AGOSTO
***********************************************************************************************************/
-- Script criacao Mat�ria Prima e Produ��o - REVIS�O PL/SQL Oracle
/* 
fabrica ( cod_fabrica, nome_fabr, fone_fabr, endere�o_fabr, cep_fabr)
produto ( cod_prod, nome_prod, peso_prod, preco_sugerido, tipo_prod ( Acabado ou Mat�ria Prima) )
prod_acabado ( cod_acabado(FK), qtde_estoque, preco_producao)  cod_acabado referencia cod_produto
prod_mater_prima (cod_mater_prima(FK) , tipo_mater_prima (Componente ou Semi-acabado), material ( se � pl�stico, a�o inoxid�vel, ferro, alum�nio, etc.) , unidade_medida ( m, kg, unidade), qtde_estoque, estoque_reposicao, preco_custo_unidade_medida) cod_mater_prima referencia cod_produto
ordem_producao ( num_ordem, cod_fabrica(fk), data_ordem, data_entrega, custo_total_producao) 
item_ordem (num_ordem(fk), cod_prod(fk), quantidade_solicitada, qtde_produzida, custo_total_producao_item)
composi��o_prod_acabado ( cod_acabado(FK), cod_mater_prima(FK), qtde_por_prod, observa��o)
*/
ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MM-YYYY HH24:MI:SS';
ALTER SESSION SET NLS_LANGUAGE = PORTUGUESE;
SELECT SESSIONTIMEZONE, CURRENT_TIMESTAMP FROM DUAL;

-- gatilho para validar a composi��o - acabado e mat�ria-prima
-- feito 02/agosto
CREATE OR REPLACE TRIGGER valida_composicao
BEFORE INSERT OR UPDATE ON composicao_prod_acabado 
FOR EACH ROW
DECLARE
vacabado SMALLINT := 0;
vmatprima SMALLINT := 0 ;
BEGIN
SELECT COUNT (*) INTO vacabado FROM prod_acabado WHERE cod_acabado = :NEW.cod_acabado;
SELECT COUNT (*) INTO vmatprima FROM prod_mater_prima WHERE cod_mater_prima  = :NEW.cod_mater_prima;
IF :NEW.cod_acabado = :NEW.cod_mater_prima THEN
RAISE_APPLICATION_ERROR ( -20001, 'Produto acabado e mat�ria-prima n�o podem coincidir ! ');
END IF ;
IF NVL(vacabado,0) = 0 THEN
RAISE_APPLICATION_ERROR ( -20002, 'Produto acabado n�o localizado ! ');
END IF ;
IF NVL(vmatprima,0) = 0 THEN
RAISE_APPLICATION_ERROR ( -20003, 'Produto mat�ria-prima n�o localizado ! ');
END IF ; 
END ;

-- testando
INSERT INTO composicao_prod_acabado VALUES ( 9, 9, 1, null);
INSERT INTO composicao_prod_acabado VALUES ( 11, 1, 1, null);
INSERT INTO composicao_prod_acabado VALUES ( 9, 18, 1, null);

/* 1- Elabore uma fun��o para retornar a quantidade a ser usada na composi��o
de um produto acabado passando como par�metros o nome ou parte do nome do produto acabado e da mat�ria prima. 
Fa�a os tratamentos necess�rios.
A quantidade usada representa a unidade de medida da mat�ria prima, por exemplo,
se para fazer uma pe�a de pl�stico usa-se granulado de polipropileno medido em Kg,
estar� registrado na quantidade usada como 0,300 - que equivale a 0,3 kg ou 300 gramas
(n�o � para converter unidades !!! isto � s� um exemplo).*/
-- feito 02/agosto
CREATE OR REPLACE FUNCTION get_composicao ( vacabado produto.nome_prod%TYPE, vmatprima produto.nome_prod%TYPE)
RETURN INTEGER
IS vcompo INTEGER := 0 ;
vtem_acab SMALLINT := 0 ;
vtem_mprima SMALLINT := 0 ;
BEGIN
SELECT COUNT(*) INTO vtem_acab
FROM produto p WHERE UPPER(p.nome_prod) LIKE '%'||UPPER(vacabado)||'%' ;
SELECT COUNT(*) INTO vtem_mprima
FROM produto p WHERE UPPER(p.nome_prod) LIKE '%'||UPPER(vmatprima)||'%' ;

IF vtem_acab = 0 THEN
RAISE_APPLICATION_ERROR ( -20001, 'Produto acabado n�o localizado ! Melhore sua busca !');
ELSIF vtem_mprima = 0 THEN
RAISE_APPLICATION_ERROR ( -20002, 'Mat�ria Prima n�o localizada ! Melhore sua busca !');
ELSIF vtem_acab > 1 OR vtem_mprima > 1 THEN
RAISE_APPLICATION_ERROR ( -20002, 'Existem produtos com mais de uma ocorr�ncia ! Melhore sua busca !');
ELSIF vtem_acab = 1 AND vtem_mprima = 1 THEN
SELECT cpa.qtde_por_prod INTO vcompo
FROM produto pacab, prod_acabado pa, prod_mater_prima pmp, COMPOSICAO_PROD_ACABADO cpa, produto pmprima
WHERE pacab.COD_PROD = pa.COD_ACABADO
AND pmprima.COD_PROD = pmp.COD_MATER_PRIMA
AND cpa.COD_ACABADO = pa.COD_ACABADO
AND cpa.COD_MATER_PRIMA = pmp.COD_MATER_PRIMA
AND UPPER(pmprima.nome_prod) LIKE '%'||UPPER(vmatprima)||'%' 
AND UPPER(pacab.nome_prod) LIKE '%'||UPPER(vacabado)||'%' ;
END IF;
RETURN NVL(vcompo,0) ;
END;

SELECT get_composicao ('motor diesel 2.0', 'bloco motor diesel' ) FROM dual ;


/********************************************************************************************************************
-- AULA_2 09 DE AGOSTO
***************************************************************************************************************/

-- fun��o que retorna o estoque da mat�ria prima passando o c�digo como par�metro
CREATE OR REPLACE FUNCTION get_estoque ( vmatprima IN prod_mater_prima.cod_mater_prima%TYPE)
RETURN INTEGER IS
vestoque prod_mater_prima.qtde_estoque%TYPE ;
BEGIN
SELECT qtde_estoque INTO vestoque
FROM prod_mater_prima
WHERE cod_mater_prima = vmatprima ;
RETURN vestoque ;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR ( -20010, 'Produto '||TO_CHAR(vmatprima)||' n�o encontrado !!!') ;
END ;

SELECT get_estoque ( (SELECT pmp.cod_mater_prima
                                      FROM prod_mater_prima pmp JOIN produto p
                                      ON ( pmp.cod_mater_prima = p.cod_prod)
                                      AND UPPER(p.nome_prod) LIKE '%BREQUIM%' ) ) 
FROM dual ;

SELECT pmp.cod_mater_prima
FROM prod_mater_prima pmp JOIN produto p
ON ( pmp.cod_mater_prima = p.cod_prod)
AND UPPER(p.nome_prod) LIKE '%BREQUIM%' ;

-- aula 09 de agosto
/* gatilho para verificar se existe estoque de mat�ria-prima suficiente para a produ��o
de um item acabado. Um produto acabado � composto de v�rias mat�rias primas */

-- //Dando erro a partir daqui. Arrumar depois//  --

CREATE OR REPLACE TRIGGER verifica_estoque
BEFORE INSERT OR UPDATE ON item_ordem
FOR EACH ROW
DECLARE
vqtde_estq INTEGER := 0 ;
vqtde_solicitada INTEGER := 0 ;
CURSOR composicao IS
  SELECT cmp.cod_mater_prima, 
     ( SELECT quantidade_composicao ( (SELECT nome_prod FROM produto WHERE cod_prod = :NEW.cod_prod),
                                                               (SELECT nome_prod FROM produto WHERE cod_prod = cmp.cod_mater_prima))
       FROM dual ) AS qtde_composicao 
  FROM composicao_prod_acabado cmp
  WHERE cmp.cod_acabado = :NEW.cod_prod ;
BEGIN
    FOR i IN composicao LOOP
       IF INSERTING THEN 
           SELECT ( :NEW.quantidade_solicitada * i.qtde_composicao) INTO vqtde_solicitada FROM dual ;
      ELSIF UPDATING THEN
        SELECT ( (:NEW.quantidade_solicitada - :OLD.quantidade_solicitada)* i.qtde_composicao) INTO vqtde_solicitada FROM dual ;
      END IF ;
           SELECT get_estoque (i.cod_mater_prima) INTO vqtde_estq FROM dual ;
       IF  vqtde_solicitada > vqtde_estq THEN
        RAISE_APPLICATION_ERROR ( -20030, 'Mat�ria Prima '||TO_CHAR(i.cod_mater_prima)||' n�o tem estoque suficiente!!!') ;
       END IF ;
       vqtde_solicitada := 0 ;
    END LOOP ;
END ;

  
SELECT * FROM produto;
select * from composicao_prod_acabado;
DROP TRIGGER verifica_estoque;

-- Mesma trigger
CREATE OR REPLACE TRIGGER verifica_estoque
BEFORE INSERT OR UPDATE ON item_ordem
FOR EACH ROW
DECLARE
vqtde_estq INTEGER :=0;
vqtde_solicitada INTEGER :=0;
CURSOR composicao IS
 SELECT cmp.cod_mater_prima,
      (SELECT quantidade_composicao ((SELECT nome_prod FROM produto WHERE cod_prod = :NEW.cod_prod),
                                     (SELECT nome_prod FROM produto WHERE cod_prod = cmp.cod_mater_prima))
      
      FROM dual) AS qtde_composicao 
      FROM composicao_prod_acabado cmp
      WHERE cmp.cod_acabado = :NEW.cod_prod;
                                                                       
BEGIN
--SELECT 1 INTO vqtde_estq FROM dual;  // S� para teste
     FOR i IN composicao LOOP
          IF INSERTING THEN
          SELECT (:NEW.quantidade_solicitada * i.qtde_composicao)INTO vqtde_solicitada FROM dual;
          ELSIF UPDATING THEN
          SELECT ((:NEW.quantidade_solicitada - :OLD.quantidade_solicitada) * i.qtde_composicao)INTO vqtde_solicitada FROM dual;
          END IF;
          SELECT get_estoque (i.cod_mater_prima) INTO vqtde_estq FROM dual;
          IF vqtde_solicitada > vqtde_estq THEN
          RAISE_APPLICATION_ERROR ( -20030,'Mat�ria Prima '||TO_CHAR(i.cod_mater_prima)||' n�o tem estoque suficiente!!!');
          END IF;
         vqtde_solicitada := 0;
     END LOOP;

END;


-- testando
SELECT * FROM item_ordem ;
DELETE FROM item_ordem WHERE cod_prod = 9 AND num_ordem = 1001 ;
SELECT * FROM composicao_prod_acabado WHERE cod_acabado = 9 ;
SELECT * FROM prod_mater_prima WHERE cod_mater_prima = 13 ;
INSERT INTO item_ordem VALUES ( 1001, 9, 0, null, 2) ;
select * from prod_mater_prima;
UPDATE prod_mater_prima SET qtde_estoque = 10 ;

-- aula 09 de agosto
/* gatilho para atualizar o estoque de mat�ria-prima para a produ��o
de um item acabado. Um produto acabado � composto de v�rias mat�rias primas */
DROP TRIGGER atualiza_estoque;
CREATE OR REPLACE TRIGGER atualiza_estoque
AFTER INSERT OR UPDATE ON item_ordem
FOR EACH ROW
DECLARE
vqtde_atualiza INTEGER := 0 ;
CURSOR composicao IS
  SELECT cmp.cod_mater_prima, 
     ( SELECT quantidade_composicao ( (SELECT nome_prod FROM produto WHERE cod_prod = :NEW.cod_prod),
                                                               (SELECT nome_prod FROM produto WHERE cod_prod = cmp.cod_mater_prima))
       FROM dual ) AS qtde_composicao 
  FROM composicao_prod_acabado cmp
  WHERE cmp.cod_acabado = :NEW.cod_prod ;
BEGIN
    FOR i IN composicao LOOP
       IF INSERTING THEN 
           SELECT ( :NEW.quantidade_solicitada * i.qtde_composicao) INTO vqtde_atualiza FROM dual ;
      ELSIF UPDATING THEN
        SELECT ( (:NEW.quantidade_solicitada - :OLD.quantidade_solicitada)* i.qtde_composicao) INTO vqtde_atualiza FROM dual ;
      END IF ;
      -- atualiza a quantidade em estoque da mat�ria prima usada no prod acabado     
      UPDATE prod_mater_prima SET qtde_estoque = qtde_estoque - vqtde_atualiza
      WHERE cod_mater_prima = i.cod_mater_prima ;
       vqtde_atualiza := 0 ;
    END LOOP ;
END ;
-- testando
SELECT * FROM item_ordem ;
UPDATE prod_mater_prima SET qtde_estoque = 10 ;
DELETE FROM item_ordem WHERE cod_prod = 9 AND num_ordem = 1001 ;
SELECT * FROM composicao_prod_acabado WHERE cod_acabado = 9 ;
SELECT * FROM prod_mater_prima WHERE cod_mater_prima = 13 ;
INSERT INTO item_ordem VALUES ( 1001, 9, 0, null, 2) ;
UPDATE item_ordem SET QUANTIDADE_SOLICITADA = 1 WHERE COD_PROD = 9 AND NUM_ORDEM=1001 ;

/**************************
Aula3 16/agosto - PROCEDURES
**************************/
CREATE OR REPLACE PROCEDURE composicao_acabado ( vacabado IN prod_acabado.cod_acabado%TYPE)
IS
CURSOR componentes IS
SELECT p.nome_prod, cpa.qtde_por_prod, pmp.qtde_estoque
FROM produto p JOIN prod_mater_prima pmp ON ( p.cod_prod = pmp.cod_mater_prima)
JOIN composicao_prod_acabado cpa ON ( cpa.cod_mater_prima = pmp.cod_mater_prima)
WHERE cpa.cod_acabado = vacabado ;
vnome_acabado produto.nome_prod%TYPE ;
BEGIN
SELECT nome_prod INTO vnome_acabado FROM produto WHERE cod_prod = vacabado ;
DBMS_OUTPUT.PUT_LINE( vnome_acabado) ;
DBMS_OUTPUT.PUT_LINE ( RPAD( '-', 50, '-') );
DBMS_OUTPUT.PUT_LINE ('Materia Prima        Qtde composi��o   Qtde Estoque') ;
FOR k IN componentes LOOP
DBMS_OUTPUT.PUT_LINE (RPAD(k.nome_prod,30, ' ')
                                         ||RPAD(TO_CHAR(k.qtde_por_prod),15,' ')
                                         ||TO_CHAR(k.qtde_estoque)) ;
END LOOP ;
END ;
-- executando
BEGIN
composicao_acabado ( 9) ;
END;

/*Elabore um controle para exibir uma determinada ordem de produ��o com o seguinte formato:

N� Ordem Produ��o : 0207   Data : 20/07/2018  F�brica : XYZ Fabril Ltda.
----------------------------------------------------------------------------------------------------------------------
Item	Produto		              Pre�o Produ��o	   Qtde Solicitada	Valor Item	Valor Produ��o
 1	Cilindro Compressor	        134,00			          2	  	        268,00           	268,00
2	Motor Compressor	  ...       219,00			          3	  	        657,00	          925,00
3	Admissor Press�o  	           67,00			          6	   	        402,00	         1327,00
------------------------------------------------------------------------------------------------------------------------
Total OP : 1327,00
*/
CREATE OR REPLACE PROCEDURE lista_ordem_producao ( vordem IN ordem_producao.num_ordem%TYPE)
IS
CURSOR ordem IS
SELECT p.nome_prod AS nome, pa.preco_producao AS preco, io.quantidade_solicitada AS qtde, 
             (pa.preco_producao* io.quantidade_solicitada) AS valoritem
FROM produto p, item_ordem io, prod_acabado pa
WHERE p.cod_prod = io.cod_prod
AND io.cod_Prod = pa.cod_acabado
AND io.num_ordem = vordem ;
vtotal ordem_producao.custo_total_producao%TYPE ;
num_item SMALLINT := 1;
vcabecalho CHAR(100) ;
vseparador CHAR(100) := RPAD('-',99,'-');
BEGIN
SELECT 'N� Ordem Produ��o :'||TO_CHAR(vordem)||'     Data : '||TO_CHAR(op.data_ordem, 'DD/MON/YYYY')||
             ' F�brica :'||f.nome_fabr
             INTO vcabecalho
FROM ordem_producao op, fabrica f
WHERE op.cod_fabrica = f.cod_fabrica
AND op.num_ordem = vordem ;
vtotal := 0 ;
DBMS_OUTPUT.PUT_LINE ( vcabecalho) ;
DBMS_OUTPUT.PUT_LINE ( vseparador) ;
FOR j IN ordem LOOP
vtotal := vtotal + j.valoritem ;
DBMS_OUTPUT.PUT_LINE ( RPAD(num_item,3,' ')|| RPAD (j.nome,30,' ')|| RPAD (TO_CHAR (j.preco), 15,' ')||
     RPAD (TO_CHAR (j.qtde), 10,' ')  || RPAD (TO_CHAR (j.valoritem), 15,' ')|| TO_CHAR(vtotal)) ;
num_item := num_item + 1;                                         
END LOOP ;
DBMS_OUTPUT.PUT_LINE ( vseparador );
DBMS_OUTPUT.PUT_LINE ( 'Total OP :'||TO_CHAR ( vtotal, '$000G000D99') ) ;
END;
-- executando
BEGIN
lista_ordem_producao (1000);
END ;


/*****************************************************************************************************************************
CORRE��O DA ATIVIDADE 1
*************************************************************************************************************************/


/*Aktv 1- Elabore uma fun��o para calcular e retornar o pre�o de custo de um produto acabado 
passando como par�metros o nome ou parte do nome do produto acabado. 
Fa�a os tratamentos necess�rios. A quantidade por produto representa a unidade de medida da mat�ria prima, 
por exemplo, se para fazer uma pe�a de pl�stico usa-se granulado de polipropileno medido em Kg, 
estar� registrado na quantidade por produto como 0,300 - que equivale a 0,3 kg ou 300 gramas 
(n�o � para converter unidades !!! isto � s� um exemplo). 
O pre�o ser� apresentado por unidade de medida , por exemplo R$ 8,00/kg. 
Lembre-se que um produto acabado pode ser composto por v�rias mat�rias primas (semi-acabadas ou componentes).*/
CREATE OR REPLACE FUNCTION preco_custo (vnome IN produto.nome_prod%TYPE)
RETURN NUMBER
IS vpreco prod_acabado.preco_producao%TYPE := 0 ;
vsetem SMALLINT := 0 ;
BEGIN
SELECT COUNT(*) INTO vsetem 
FROM Produto WHERE UPPER(nome_prod)
LIKE '%'||UPPER(vnome)||'%' ;
IF vsetem = 0 THEN 
  RAISE_APPLICATION_ERROR ( -20010, 'Produto n�o encontrado !!!') ;
ELSIF vsetem > 1 THEN
   RAISE_APPLICATION_ERROR ( -20011, 'Existe mais de um produto com este nome !!!') ;
ELSIF vsetem = 1 THEN
    SELECT SUM ( cpa.qtde_por_prod * pmp.preco_custo_unidade_medida ) INTO vpreco
   FROM produto p, prod_mater_prima pmp, composicao_prod_acabado cpa, prod_acabado pa
   WHERE p.cod_prod = pa.cod_acabado
   AND pa.cod_acabado = cpa.cod_acabado
   AND pmp.cod_mater_prima = cpa.cod_mater_prima
   AND UPPER(p.nome_prod) LIKE '%'||UPPER(vnome)||'%' ;
END IF ;
RETURN NVL(vpreco,0) ;
END ;

SELECT preco_custo('motor eletrico 10hp') FROM dual ;

SELECT nome_prod from produto ;

/* Aktv 2- Elabore um controle para exibir um invent�rio de estoque no seguinte formato,
passando como par�metros o per�odo e o c�digo da mat�ria prima :

Produto Mat�ria-Prima : 01065 � Granulado de Polipropileno � R$ 18,32 / Kg  
----------------------------------------------------------------------------------------------------------------------
N� OP	Data Produ��o		Produto Acabado	Qtde Solicitada	Qtde/prod	Qtde Usada
104	22/03/2016		Caixa de Reten��o		3		0,930		 2,790		
167	29/03/2016		Capa Motor 1.6		29		1,200  	  	37,590
201	06/04/2016  		Caixa de Jun��o 4�		58		0,340 	  	57,310
------------------------------------------------------------------------------------------------------------------------
Total Utilizado per�odo 01/03 a 30/04  : 57,310 kg */

CREATE OR REPLACE PROCEDURE inventario (vmp IN prod_mater_prima.cod_mater_prima%TYPE,
vini IN ordem_producao.data_entrega%TYPE, vfim IN ordem_producao.data_entrega%TYPE )
IS 
CURSOR inventario IS
SELECT op.num_ordem, op.data_ordem, p.nome_prod, io.cod_prod, cpa.cod_mater_prima, io.quantidade_solicitada, cpa.qtde_por_prod,
(cpa.qtde_por_prod*io.quantidade_solicitada) AS usada
FROM produto p, ordem_producao op, composicao_prod_acabado cpa, prod_acabado pa, prod_mater_prima pmp, item_ordem io
WHERE pa.cod_acabado = p.cod_prod
AND pa.cod_acabado = cpa.cod_acabado
AND pmp.cod_mater_prima = cpa.cod_mater_prima
AND pa.cod_acabado = io.cod_prod
AND io.num_ordem = op.num_ordem
AND cpa.cod_mater_prima = vmp
AND op.data_ordem BETWEEN vini AND vfim 
order BY 1, 4, 5 ;
vcabecalho VARCHAR2(100) ;
vseparador VARCHAR2(100) := RPAD('-',99,'-') ;
vtotal NUMBER(10,2) := 0 ;
BEGIN
SELECT 'Produto Mat�ria-Prima : '||p.cod_prod||'   '||p.nome_prod||'-'||
'R$ '||TO_CHAR( pmp.preco_custo_unidade_medida)||'/'||pmp.unidade_medida
INTO vcabecalho
FROM produto p, prod_mater_prima pmp
WHERE p.cod_prod = pmp.cod_mater_prima
AND p.cod_prod = vmp ;
DBMS_OUTPUT.PUT_LINE( vcabecalho) ;
DBMS_OUTPUT.PUT_LINE ( vseparador) ;
DBMS_OUTPUT.PUT_LINE ('N� OP	Data Produ��o		Produto Acabado	Qtde Solicitada	Qtde/prod	Qtde Usada') ;
FOR j IN inventario LOOP
vtotal := vtotal  + j.usada ;
DBMS_OUTPUT.PUT_LINE(TO_CHAR( j.num_ordem)||' - '||TO_CHAR(j.data_ordem, 'DD/MM/YYYY')
||'  -  '||RPAD(j.nome_prod,30,' ')||RPAD(TO_CHAR(j.quantidade_solicitada),15, ' ')||
RPAD(TO_CHAR(j.qtde_por_prod),15, ' ')||
TO_CHAR(vtotal)) ;
END LOOP;
DBMS_OUTPUT.PUT_LINE ( vseparador) ;
DBMS_OUTPUT.PUT_LINE ( 'Total utilizado no per�odo de '||TO_CHAR(vini, 'DD/MM/YY')||' a '||
TO_CHAR(vfim, 'DD/MM/YY')||' : '||TO_CHAR(vtotal) ) ;
END;

BEGIN
inventario (5, current_date - 100, current_date) ;
END;

