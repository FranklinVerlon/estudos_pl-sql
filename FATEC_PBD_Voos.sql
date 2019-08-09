Alter Session Set NLS_language='BRAZILIAN PORTUGUESE';
Alter Session Set NLS_TERRITORY = 'BRAZIL';
Alter Session Set NLS_NUMERIC_CHARACTERS=',.';
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';

DROP TABLE fonte CASCADE CONSTRAINTS ;
CREATE TABLE fonte( 
Voos VARCHAR2(50),
Companhia_Aerea VARCHAR2(70),
Codigo_Tipo_Linha VARCHAR2(20),
Partida_Prevista VARCHAR2(30),
Partida_Real VARCHAR2(30),
Chegada_Prevista VARCHAR2(30),
Chegada_Real VARCHAR2(30),
Situacao_Voo VARCHAR2(20),
Codigo_Justificativa VARCHAR2(100),
Aeroporto_Origem VARCHAR2(50),
Cidade_Origem VARCHAR2(50),
Estado_Origem VARCHAR2(50),
Pais_Origem VARCHAR2(50),
Aeroporto_Destino VARCHAR2(50),
Cidade_Destino VARCHAR2(50),
Estado_Destino VARCHAR2(50),
Pais_Destino VARCHAR2(50),
LongDest VARCHAR2(20),
LatDest VARCHAR2(15),
LongOrig VARCHAR2(20),
LatOrig VARCHAR2(15));

select count(*) from fonte ;

ALTER TABLESPACE SYSTEM ADD DATAFILE '\oraclexe\app\oracle\oradata\XE\system2.dbf' SIZE 10M AUTOEXTEND ON NEXT 50M MAXSIZE 2000M ;

truncate table fonte;

SELECT * FROM 
(SELECT * FROM fonte) teste
WHERE ROWNUM <= 25;

/*** mapeamento para novas tabelas ***
Voos -> VOO+CIA
Companhia_Aerea -> VOO+CIA 
Codigo_Tipo_Linha -> VOO+CIA
Partida_Prevista ->  voo voado
Partida_Real -> voo voado
Chegada_Prevista -> voo voado
Chegada_Real -> voo voado
Situacao_Voo -> voo voado
Codigo_Justificativa -> voo voado
Aeroporto_Origem -> aeroportos | voo voado
Cidade_Origem -> local
Estado_Origem  -> local 
Pais_Origem  -> local
Aeroporto_Destino -> aeroportos | voo voado  
Cidade_Destino  -> local
Estado_Destino  -> local
Pais_Destino  -> local
LongDest -> aeroportos
LatDest -> aeroportos
LongOrig -> aeroportos
LatOrig -> aeroportos 
****/

-- montagem da tabela localidade: cidade,estado e pais com um codigo pra cidade - ssequencia

--RTRIM TIRA OS ESPACOS EM BRANCO
-- MAX PEGA O MAIOR LENGTH PEGA O COMPRIMENTO DO CAMPO
-- PEGANDO O tamanho DO MAIOR STRING
SELECT MAX(LENGTH(RTRIM(cidade_origem))) FROM fonte; -- 27 ORIGEM
SELECT MAX(LENGTH(RTRIM(cidade_destino))) FROM fonte; -- 27 DESTINO
SELECT MAX(LENGTH(RTRIM(estado_destino))) FROM fonte; -- 3
SELECT MAX(LENGTH(RTRIM(pais_destino))) FROM fonte; -- 22 

DROP TABLE localidade CASCADE CONSTRAINTS;
CREATE TABLE localidade 
(id_local SMALLINT,
cidade VARCHAR2(30),
estado CHAR(3),
pais VARCHAR2(25));

--sequencia para identificação da localidade
DROP SEQUENCE local_seq;
CREATE SEQUENCE local_seq;

SELECT cidade, estado, pais FROM
--SELECIONANDO OS DADOS
(SELECT DISTINCT RTRIM(cidade_origem) AS cidade, RTRIM(estado_origem) AS estado, RTRIM(pais_origem) AS pais
FROM fonte
UNION --COMO SE FOSSE SOMA, UNE OS DOIS CONJUNTOS, SOMA 
(SELECT DISTINCT RTRIM(cidade_destino) AS cidade, RTRIM(estado_destino) AS estado, RTRIM(pais_destino) AS pais
FROM fonte)) city;

-- Procedure para popular a tabela localidade
CREATE OR REPLACE PROCEDURE popula_local(vmensagem IN CHAR)
IS
BEGIN
INSERT INTO localidade (cidade, estado, pais)
SELECT cidade, estado, pais FROM
--SELECIONANDO OS DADOS
(SELECT DISTINCT RTRIM(cidade_origem) AS cidade, RTRIM(estado_origem) AS estado, RTRIM(pais_origem) AS pais
FROM fonte
UNION --COMO SE FOSSE SOMA, UNE OS DOIS CONJUNTOS, SOMA 
(SELECT DISTINCT RTRIM(cidade_destino) AS cidade, RTRIM(estado_destino) AS estado, RTRIM(pais_destino) AS pais
FROM fonte)) city;
-- atualizando o id_local
UPDATE localidade SET id_local = local_seq.nextval; -- para todas as linhas adiciona um id
COMMIT;
DBMS_OUTPUT.PUT_LINE(vmensagem);
END;
-- EXECUTANDO
BEGIN 
popula_local('Tenho medo que de certo!!');
END;

--CONFERINDO
SELECT * FROM localidade;

--CHUMBANDO ID LOCAL COMO PK
ALTER TABLE localidade ADD CONSTRAINT pk_local PRIMARY KEY (id_local);

/**** voos da cia ****/
SELECT COUNT(*) FROM
(SELECT DISTINCT RTRIM(voos), RTRIM(companhia_aerea), RTRIM(codigo_tipo_linha), RTRIM(cidade_origem),RTRIM(cidade_destino)
FROM fonte ORDER BY 1)voo;

/*** aeroportos ****/

DROP TABLE aeroporto CASCADE CONSTRAINTS;
CREATE TABLE aeroporto
(id_aero INTEGER,
aeroporto VARCHAR2(50),
cidade VARCHAR2(30),
longitude VARCHAR2(20), -- 12 tamanho total, 8 dps da virgula
latitude VARCHAR2(20));

DROP SEQUENCE aero_seq;
CREATE SEQUENCE aero_seq;

SELECT MAX(LENGTH(RTRIM(aeroporto_origem))) FROM fonte; --48

SELECT DISTINCT RTRIM(aeroporto_origem), RTRIM(cidade_origem), RTRIM(longorig), RTRIM(latorig)
FROM fonte
UNION
(SELECT DISTINCT RTRIM(aeroporto_destino), RTRIM(cidade_destino), RTRIM(longdest), RTRIM(latdest)
FROM fonte)ORDER BY 1;

--PROCEDURE PARA POUPLAR O AEROPORTO
CREATE OR REPLACE PROCEDURE popula_aero(vtexto IN CHAR)
IS
BEGIN
INSERT INTO aeroporto(aeroporto, cidade, longitude, latitude)
SELECT DISTINCT RTRIM(aeroporto_origem), RTRIM(cidade_origem), RTRIM(longorig), RTRIM(latorig)
FROM fonte
UNION
(SELECT DISTINCT RTRIM(aeroporto_destino), RTRIM(cidade_destino), RTRIM(longdest), RTRIM(latdest)
FROM fonte)ORDER BY 1;
--atualizando o id
UPDATE aeroporto SET id_aero = aero_seq.nextval;
COMMIT;
DBMS_OUTPUT.PUT_LINE(vtexto);
END;

--executando
BEGIN
popula_aero('blabla');
END;

--trocando o nome da cidade pelo id local
ALTER TABLE aeroporto ADD id_local SMALLINT;

UPDATE aeroporto a SET a.id_local = (
SELECT l.id_local
FROM localidade l WHERE UPPER(a.cidade) = UPPER(l.cidade));

SELECT a.cidade, l.cidade
FROM aeroporto a, localidade l
WHERE a.id_local = l.id_local;

ALTER TABLE aeroporto ADD CONSTRAINT fk_local FOREIGN KEY (id_local)
REFERENCES localidade (id_local);

ALTER TABLE aeroporto DROP COLUMN cidade;

ALTER TABLE aeroporto ADD CONSTRAINT pk_aero PRIMARY KEY (id_aero);

--testando se funcionou
SELECT a.aeroporto, l.cidade
FROM aeroporto a, localidade l
WHERE a.id_local = l.id_local;


/**** a partir daqui aula 30/08 agosto **/

-- ESTAVA COM LATITUDE/LONGITUDE REPETIDA
-- SELECT * FROM aeroporto WHERE UPPER(aeroporto) LIKE '%PONTA GROSSA%' OR UPPER(aeroporto) LIKE '%PENA%';
DELETE FROM aeroporto WHERE UPPER(aeroporto) LIKE '%PONTA GROSSA%';

ALTER TABLE aeroporto ADD(longitude_local NUMBER(12,8), latitude_local NUMBER(12,8));

SELECT aeroporto, TO_NUMBER(SUBSTR(longitude,1,12),'999.99999999')
FROM aeroporto;

-- SETANDO NOVAS COLUNAS (ESSAS NOVAS COLUNAS SÃO NUMERICAS, SERVEM PARA CALCULAR LONGITUDE/LATITUDE)
UPDATE aeroporto SET longitude_local = TO_NUMBER(SUBSTR(longitude,1,12),'999.99999999'), 
                     latitude_local = TO_NUMBER(SUBSTR(latitude,1,12),'999.99999999');

--CONFERINDO SE FOI
SELECT longitude_local, latitude_local
FROM aeroporto;

-- EXCLUINDO COLUNAS ANTIGAS E ALTERANDO O NOME DAS NOVAS
ALTER TABLE aeroporto DROP COLUMN longitude;
ALTER TABLE aeroporto DROP COLUMN latitude;
ALTER TABLE aeroporto RENAME COLUMN longitude_local TO longitude_aero;
ALTER TABLE aeroporto RENAME COLUMN latitude_local TO latitude_aero;

DESC AEROPORTO;

-- função para calcular a distância entre dois pontos da TERRA utilizando
-- as coordenadas geograficas de longitude e latitude (origem e destino)
CREATE OR REPLACE FUNCTION distancia(lat_ori IN NUMBER, long_ori IN NUMBER, 
                                    lat_dest IN NUMBER, long_dest IN NUMBER, 
                                    radius IN NUMBER DEFAULT 6387.7)
RETURN NUMBER IS 
grau_para_radiano NUMBER := 57.29577951;
BEGIN

RETURN (NVL(radius,0) * 
    ACOS((SIN(NVL(lat_ori,0)/grau_para_radiano) * SIN(NVL(lat_dest,0)/grau_para_radiano) ) +
    (COS(NVL(lat_ori,0)/grau_para_radiano) * COS(NVL(lat_dest,0)/grau_para_radiano) *
    COS(NVL(long_dest,0)/grau_para_radiano - NVL(long_ori,0)/grau_para_radiano))));
END;

SELECT distancia(-23.43,-46.47,-22.81,-43.24) FROM dual; -- GRU -23.43 / -46.47 RJ -22.81 / -43.24
SELECT * FROM aeroporto WHERE UPPER(aeroporto) LIKE '%GUARUL%';
SELECT * FROM aeroporto WHERE UPPER(aeroporto) LIKE '%JANEIRO%';       

--LIMPANDO A BASE PARA OS VÔOS
SELECT DISTINCT RTRIM(voos), RTRIM(companhia_aerea), RTRIM(codigo_tipo_linha),
RTRIM(cidade_origem), RTRIM(cidade_destino)
FROM fonte
order by 1;

-- CRIANDO UMA RÉPLICA DE FONTE SUBSTITUINDO OS TEXTOS PELOS IDS
DROP TABLE fontelimpa CASCADE CONSTRAINTS;
CREATE TABLE fontelimpa
( id_voo CHAR(10),
cia_aerea CHAR(50),
cod_tp_linha CHAR(13),
id_aero_origem SMALLINT,
id_local_origem SMALLINT,
id_aero_destino SMALLINT,
id_local_destino SMALLINT);


SELECT DISTINCT RTRIM(voos)
FROM fonte;

---SELECT MAX(LENGTH(voos)) FROM fonte;

-- procedure para popular réplica de fonte tratando os dados
CREATE OR REPLACE PROCEDURE popula_replica( vteste IN CHAR)
IS 
CURSOR fontelimpa IS
SELECT RTRIM(voos) AS voo ,RTRIM(companhia_aerea) AS cia, RTRIM(codigo_tipo_linha) AS linha, 
    TO_NUMBER(SUBSTR(longorig,1,12),'999.99999999') as lori,
    TO_NUMBER(SUBSTR(latorig,1,12),'999.99999999') AS latori, 
    RTRIM(UPPER(cidade_origem)) AS cityori,
    TO_NUMBER(SUBSTR(longdest,1,12),'999.99999999') AS ldest,
    TO_NUMBER(SUBSTR(latdest,1,12),'999.99999999') AS latdest,
    RTRIM(UPPER(cidade_destino)) AS citydest
FROM fonte;
vaero_ori SMALLINT;
vaero_dest SMALLINT;
vcity_ori SMALLINT;
vcity_dest SMALLINT;
vquantos SMALLINT := 0;
BEGIN
FOR K IN fontelimpa LOOP
vquantos := vquantos + 1;
SELECT id_aero INTO vaero_ori FROM aeroporto WHERE longitude_aero = k.lori AND latitude_aero= k.latori;
SELECT id_aero INTO vaero_dest FROM aeroporto WHERE longitude_aero = k.ldest AND latitude_aero= k.latdest;
SELECT id_local INTO vcity_ori FROM localidade WHERE UPPER(cidade) = k.cityori;
SELECT id_local INTO vcity_dest FROM localidade WHERE UPPER(cidade) = k.citydest;
-- inserindo a linha em fontelimpa
INSERT INTO fontelimpa VALUES (k.voo, k.cia, k.linha, vaero_ori, vcity_ori, vaero_dest, vcity_dest);
END LOOP;
DBMS_OUTPUT.PUT_LINE(TO_CHAR(vquantos));
COMMIT;
END;
--EXECUTANDO
BEGIN
popula_replica('sucessfull running!!!!');
END;

SELECT COUNT(*) FROM fontelimpa;

/** AULA 06/09 **/

ALTER TABLE fontelimpa ADD atualizado CHAR(1);
UPDATE fontelimpa SET atualizado = 'N';

--otimizando a busca
DROP INDEX idvoo_idx;
CREATE INDEX idvoo_dix on fontelimpa(id_voo);
DROP INDEX idlinha_idx;
CREATE INDEX idlinha_idx on fontelimpa(cod_tp_linha);
DROP INDEX aeroorig_idx;
CREATE INDEX aeroorig_idx on fontelimpa(id_aero_origem);
DROP INDEX aerodest_idx;
CREATE INDEX aerodest_idx on fontelimpa(id_aero_destino);

SELECT COUNT(*) FROM(
SELECT f1.id_voo, f1.cia_aerea, f1.cod_tp_linha, f1.id_aero_origem, f1.id_aero_destino, COUNT(*) AS f1conta
FROM fontelimpa f1
GROUP BY f1.id_voo, f1.cia_aerea, f1.cod_tp_linha, f1.id_aero_origem, f1.id_aero_destino
ORDER BY 1,6 DESC) teste;

/****************************************************
Procedure para limpar os duplicados
mesmo vôo que tem id, origem e destino iguais mas tipo da linha diferente
parte como Nacional e parte como Regional
1- utiliza dois cursores : o primeiro seleciona todas as linhas e agrupa por voo, aeroporto origem e destino, cia aerea não influi
e faz a contagem, ordenando pela maior contagem, assim se tiver coincidência em tudo mas um Nacional e outro Regional
coloca quem tem mais primeiro
2- o segundo cursor varre a tabela para o mesmo voo,aeroporto origem e destino mas tipo linha diferente e faz a contagem também
Então o k do primeiro pode ser Nacional e o segundo pega Regional
3- testa no IF quem ganha a contagem, se Nacional ou regional e carimba as linhas com o tipo de linha vencedor, assim elimina
as duplicatas com tipo linha diferentes *****/
CREATE OR REPLACE PROCEDURE limpa_voo_duplicado ( teste IN CHAR DEFAULT 'Deu certo!!!')
IS 
CURSOR fonte1 IS
SELECT f1.id_voo, f1.cia_aerea, f1.cod_tp_linha, f1.id_aero_origem, f1.id_aero_destino, COUNT(*) AS f1conta
FROM fontelimpa f1
GROUP BY f1.id_voo, f1.cia_aerea, f1.cod_tp_linha, f1.id_aero_origem, f1.id_aero_destino
ORDER BY 1,6 DESC;
vf1 SMALLINT :=0;
vf2 SMALLINT :=0;
BEGIN
FOR k IN fonte1 LOOP
    vf1 := vf1 +1;
    vf2 :=0;
    FOR m IN(SELECT f2.id_voo, f2.cia_aerea, f2.cod_tp_linha, f2.id_aero_origem, f2.id_aero_destino, 
                COUNT(*) AS f2conta
                FROM fontelimpa f2
                WHERE f2.id_voo = k.id_voo AND f2.id_aero_origem = K.id_aero_origem
                AND f2.id_aero_destino = k.id_aero_destino AND f2.cod_tp_linha != k.cod_tp_linha
                AND f2.atualizado = 'N'
                GROUP BY f2.id_voo, f2.cia_aerea, f2.cod_tp_linha, f2.id_aero_origem, f2.id_aero_destino) LOOP
        vf2:= vf2 + 1;    
        -- verificando se para o mesmo vôo, aero origem e destino quem ganha é o tipo linha de f1 ou f2
        IF k.id_voo = m.id_voo AND k.id_aero_origem = m.id_aero_origem
            AND k.id_aero_destino = m.id_aero_destino AND k.cod_tp_linha != m.cod_tp_linha THEN
            DBMS_OUTPUT.PUT_LINE(vf1||'//'||vf2);    
            --VERFICANDO QUEM TEM MAIS CONTAGEM
            IF k.f1conta >= m.f2conta THEN -- CARIMBA O TIPO linha de f1 nas linhas em que está diferente
                UPDATE fontelimpa SET cod_tp_linha = k.cod_tp_linha, atualizado = 'S'
                WHERE id_voo = k.id_voo AND id_aero_origem = k.id_aero_origem
                AND id_aero_destino = k.id_aero_destino
                AND cod_tp_linha = m.cod_tp_linha;
            ELSIF k.f1conta < m.f2conta THEN -- CARIMBA O TIPO linha de f1 nas linhas em que está diferente
                UPDATE fontelimpa SET cod_tp_linha = k.cod_tp_linha, atualizado = 'S'
                WHERE id_voo = k.id_voo AND id_aero_origem = k.id_aero_origem
                AND id_aero_destino = k.id_aero_destino
                AND cod_tp_linha = k.cod_tp_linha;
            END IF;
            END IF;
    END LOOP; -- loop do cursor de dentro f2
END LOOP; -- loop do cursor de fora f1
END;

-- executando a limpeza
BEGIN
limpa_voo_duplicado() ;
END ;

select * from fontelimpa;

SELECT COUNT(*) FROM fontelimpa
WHERE atualizado = 'S' ;

/** CRIANDO E POPULANDO A TABELA VOO**/
DROP TABLE voo CASCADE CONSTRAINTS;
CREATE TABLE voo
(id_voo CHAR(10),
cia_aerea CHAR(50),
cod_tp_linha CHAR(13),
id_aero_origem SMALLINT,
id_aero_destino SMALLINT);

INSERT INTO voo(id_voo, cia_aerea, cod_tp_linha, id_aero_origem, id_aero_destino)
SELECT DISTINCT(f1.id_voo), f1.cia_aerea, f1.cod_tp_linha,
                f1.id_aero_origem, f1.id_aero_destino
FROM fontelimpa f1 ORDER BY f1.id_voo;

ALTER TABLE voo ADD CONSTRAINT pk_voo PRIMARY KEY(id_voo, id_aero_origem, id_aero_destino);

select * from voo;
 -- Exercicio
 --1) Incluir uma nova coluna distância
 ALTER TABLE voo DROP COLUMN distancia;
 ALTER TABLE voo ADD distancia NUMBER;
 
 -- NÓS FIZEMOS
 --2 Popular usando a função distancia
CREATE OR REPLACE PROCEDURE popula_dis( vteste IN CHAR)
IS 
CURSOR voos IS
SELECT * from voo;
vmarca NUMBER(10,1);
BEGIN
FOR i in voos loop
SELECT distancia(latori,logori , latdest, logdest) INTO vmarca
    FROM
 (SELECT Aorigem.longitude_aero AS logori, Aorigem.latitude_aero as latori, Adestino.longitude_aero as logdest, Adestino.latitude_aero as latdest
 FROM aeroporto Aorigem, aeroporto Adestino
 WHERE i.id_aero_origem = Aorigem.id_aero
 AND i.id_aero_destino = Adestino.id_aero);

UPDATE voo SET distancia = vmarca WHERE id_voo = i.id_voo;
END LOOP;
DBMS_OUTPUT.PUT_LINE(vteste);
END;

BEGIN
popula_dis('foi');
END;
SELECT * from voo;

ALTER TABLE voo DROP COLUMN distancia;
-- CORREÇÃO ATIVIDADE 2 PROFESSOR
/* Atividade 02 : Utilizando a linguagem PL/SQL e SQL :
1 – Altere a estrutura da tabela vôo populada em aula para receber dados da distância dos vôos. */
ALTER TABLE voo ADD distancia NUMBER(10,2) ;
 
/*2 – Crie um procedimento ou função que popule a nova coluna utilizando a função distancia feita em aula
que recebe o par de latitudes e longitudes de origem e destino. */
DESC aeroporto ;
 
CREATE OR REPLACE PROCEDURE popula_distancia ( vteste IN CHAR DEFAULT 'erfolg' ) 
IS
longo aeroporto.longitude_aero%TYPE ;
lato aeroporto.latitude_aero%TYPE ;
longd aeroporto.longitude_aero%TYPE ;
latd aeroporto.latitude_aero%TYPE ;
vdist NUMBER(10,2) ;
CURSOR distanciaaero IS
SELECT * FROM voo ORDER BY id_voo ;
BEGIN
FOR k IN distanciaaero LOOP
     SELECT longitude_aero, latitude_aero INTO longo, lato FROM aeroporto WHERE id_aero= k.id_aero_origem ;
     SELECT longitude_aero, latitude_aero INTO longd, latd FROM aeroporto WHERE id_aero= k.id_aero_destino ;
     --SELECT distancia (-22.81, -43.24, -14.81, -39.03) FROM dual ;
     SELECT distancia(lato, longo, latd, longd) INTO vdist FROM dual ;
     UPDATE voo SET distancia = vdist WHERE id_voo = k.id_voo AND id_aero_origem = k.id_aero_origem
                                                                          AND id_aero_destino = k.id_aero_destino ;
END LOOP;
DBMS_OUTPUT.PUT_LINE ( vteste) ;
END;
 
-- executando
BEGIN
popula_distancia ();
END ;
 
SELECT * from voo ;

/***************************
Aula 13/setembro
***************************/

/******** tratamento para a tabela principal agora
vai conter os vôos de fato *****/
DROP TABLE voos_br CASCADE CONSTRAINTS;
CREATE TABLE voos_br
( voo_sequencia INTEGER,
 id_voo CHAR(10) ,
id_aero_origem SMALLINT ,
id_aero_destino SMALLINT,
dthora_partida_prevista TIMESTAMP,
dthora_partida_real TIMESTAMP,
dthora_chegada_prevista TIMESTAMP,
dthora_chegada_real TIMESTAMP,
situacao_voo VARCHAR2(10),
justificativa VARCHAR2(90)) ;

SELECT MAX(LENGTH(codigo_justificativa)) FROM fonte ;
SELECT MAX(LENGTH(situacao_voo)) FROM fonte ;
DESC fontelimpa ;
DESC fonte ;

/*******************************************************************************
/*** popula a tabela vôos br  com data e hora das partidas e chegadas
vôos cancelados não estão com dthora de partida e chegada real -
foi colocado NA na fonte, por isso a limpeza com DECODE ****
*******************************************************************************/
CREATE OR REPLACE PROCEDURE popula_voos_br ( vteste IN CHAR DEFAULT 'ausgeführt')
IS
CURSOR voosbr IS
SELECT RTRIM(voos) AS voo, 
   TO_NUMBER(SUBSTR(longorig,1,12),'999.99999999') AS longori, 
   TO_NUMBER(SUBSTR(latorig,1,12),'999.99999999') AS latiori,  
   TO_NUMBER(SUBSTR(longdest,1,12),'999.99999999') AS longdest,
   TO_NUMBER(SUBSTR(latdest,1,12),'999.99999999') AS latidest, 
   TO_TIMESTAMP ( DECODE( RTRIM(partida_prevista), 'NA', '0001-01-01T00:00:00Z', partida_prevista ), 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS part_prev, 
   TO_TIMESTAMP (DECODE( RTRIM(partida_real), 'NA', '0001-01-01T00:00:00Z', partida_real ) , 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS part_real,
   TO_TIMESTAMP ( DECODE( RTRIM(chegada_prevista), 'NA', '0001-01-01T00:00:00Z', chegada_prevista ), 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS cheg_prev,  
   TO_TIMESTAMP ( DECODE( RTRIM(chegada_real), 'NA', '0001-01-01T00:00:00Z', chegada_real ), 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS cheg_real,
   RTRIM ( situacao_voo) As situacao,
   RTRIM( codigo_justificativa) AS justificativa,
   rowid AS idlinha FROM fonte ;
vi SMALLINT := 0 ;
vaero_ori SMALLINT := 0 ;
vaero_dest SMALLINT := 0  ;
vrowid CHAR(20) ;
BEGIN
FOR k IN voosbr LOOP
vi := vi + 1 ;
vaero_ori := 0 ;
vaero_dest  := 0  ;
vrowid := k.idlinha ;

SELECT id_aero INTO vaero_ori FROM aeroporto WHERE longitude_aero = k.longori AND latitude_aero=k.latiori;
SELECT id_aero INTO vaero_dest FROM aeroporto WHERE longitude_aero = k.longdest AND latitude_aero=k.latidest ;
-- inserção
INSERT INTO voos_br ( id_voo, id_aero_origem, id_aero_destino, dthora_partida_prevista, dthora_partida_real ,
dthora_chegada_prevista, dthora_chegada_real , situacao_voo , justificativa ) 
VALUES ( k.voo, vaero_ori, vaero_dest, k.part_prev, k.part_real, k.cheg_prev, k.cheg_real,
                 k.situacao, k.justificativa) ;
END LOOP ;  
DBMS_OUTPUT.PUT_LINE(vi ||'-'|| vrowid) ;
COMMIT ;
--EXCEPTION
--WHEN OTHERS THEN
--DBMS_OUTPUT.PUT_LINE(vi || vrowid) ;
END ;

-- executando-- deu certo
BEGIN
popula_voos_br () ;
END ;

SELECT COUNT(*) FROM fonte
WHERE chegada_prevista IS NULL ;

SELECT COUNT(*) FROM voos_br ;
TRUNCATE TABLE voos_br ;

-- finalmente definindo a PK como id_voo + id_aero_origem + id_aero_destino + dthora prevista
-- id_voo + id_aero_origem + id_aero_destino  é FK de voos
SELECT COUNT(*)
FROM voos_br vbr JOIN voo v
ON ( vbr.id_voo = v.id_voo AND vbr.id_aero_origem = v.id_aero_origem
        AND vbr.id_aero_destino = v.id_aero_destino ) ;  -- funcionou, correspondência das 2.542.510 linhas
-- sequence para a PK de voos_br
CREATE SEQUENCE voobr_seq ;
UPDATE voos_br SET voo_sequencia = voobr_seq.nextval ;
-- definindo a PK
ALTER TABLE voos_br ADD CONSTRAINT pkvoosbr PRIMARY KEY ( voo_sequencia) ;
-- definindo a FK
ALTER TABLE voos_br ADD CONSTRAINT fkvoos FOREIGN KEY ( id_voo, id_aero_origem, id_aero_destino)
REFERENCES voo ( id_voo, id_aero_origem, id_aero_destino) ON DELETE CASCADE ;
DESC voos_br ;
DESC voo ;

--ALTERANDO A FORMA DA DATA DO SISTEMA
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';

--CONSULTAS
-- 1 QTDE DE VOOS POR COMPANHIA AREA
SELECT v.cia_aerea AS Companhia, COUNT(*) AS Qtde_voos
FROM voo v
GROUP BY v.cia_aerea
ORDER BY 1;


-- 2 QTDE DE VOOS POR COMPANHIA E TIPO DA LINHA "" pq é nome composto
SELECT v.cia_aerea AS Companhia, v.cod_tp_linha as "Tipo Linha", COUNT(*) AS Qtde_voos
FROM voo v
GROUP BY v.cia_aerea, v.cod_tp_linha
ORDER BY 1;

-- 3 - Qtde de Vôos por ano
SELECT EXTRACT (YEAR FROM vbr.dthora_partida_prevista) AS Ano, COUNT(*) AS Voos_ano
FROM voos_br vbr
WHERE vbr.situacao_voo = 'Realizado'
GROUP BY EXTRACT (YEAR FROM vbr.dthora_partida_prevista)
ORDER BY 1;

-- 3.1 - cancelados por ano
SELECT EXTRACT (YEAR FROM vbr.dthora_partida_prevista) AS Ano, COUNT(*) AS Voos_ano
FROM voos_br vbr
WHERE vbr.situacao_voo = 'Cancelado'
GROUP BY EXTRACT (YEAR FROM vbr.dthora_partida_prevista)
ORDER BY 1;

SELECT DISTINCT justificativa FROM voos_br;

--4 idem 3 tambem por cia aerea (msm coisa do 3 mas agrupa por companhia aerea tb)
SELECT v.cia_aerea AS Companhia,
EXTRACT (YEAR FROM vbr.dthora_partida_prevista) AS Ano, COUNT(*) AS Voos_ano
FROM voos_br vbr JOIN voo v 
ON(vbr.id_voo = v.id_voo AND vbr.id_aero_origem = v.id_aero_origem
    AND vbr.id_aero_destino = v.id_aero_destino)
WHERE vbr.situacao_voo = 'Realizado'
GROUP BY v.cia_aerea, EXTRACT (YEAR FROM vbr.dthora_partida_prevista)
ORDER BY 1,2;

--5 IDEM 4 tambem POR TIPO DE LINHA
SELECT v.cia_aerea AS Companhia,v.cod_tp_linha AS Linha,
EXTRACT (YEAR FROM vbr.dthora_partida_prevista) AS Ano, COUNT(*) AS Voos_ano
FROM voos_br vbr JOIN voo v 
ON(vbr.id_voo = v.id_voo AND vbr.id_aero_origem = v.id_aero_origem
    AND vbr.id_aero_destino = v.id_aero_destino)
WHERE vbr.situacao_voo = 'Realizado'
GROUP BY v.cia_aerea, v.cod_tp_linha, EXTRACT (YEAR FROM vbr.dthora_partida_prevista)
ORDER BY 1,2;

--6 - qdte de voos por aeroporto, seja chegada ou destino
SELECT a.aeroporto, COUNT(*) As Qtde_voos
FROM aeroporto a, voos_br vbr
WHERE a.id_aero = vbr.id_aero_origem
OR a.id_aero = vbr.id_aero_destino
GROUP BY a.aeroporto
ORDER BY 1;

--7 -idem 6, separando origem e destino -Não da certo - atividade
--SELECT ao.aeroporto, COUNT(*) AS Origem,


CREATE OR REPLACE PROCEDURE qtd(teste IN CHAR DEFAULT 'Deu certo!!!')
IS
CURSOR  aeroporto IS
SELECT * FROM aeroporto;

cont1 INTEGER;
cont2 INTEGER;
vnome VARCHAR2(200);
BEGIN
DBMS_OUTPUT.PUT_LINE('AEROPORTO                     QTD_ORIGEM         QTD_DESTINO');
FOR t IN aeroporto LOOP

SELECT COUNT(*) qtd INTO cont1
FROM voos_br vbr
WHERE t.id_aero = vbr.id_aero_origem;

SELECT COUNT(*) qtd INTO cont2
FROM voos_br vbr
WHERE t.id_aero = vbr.id_aero_destino;


DBMS_OUTPUT.PUT_LINE(t.aeroporto ||'  -  ' || TO_CHAR(cont1)||'  -  ' || TO_CHAR(cont2));
END LOOP;
END;

BEGIN
qtd();
END;


--8 - 10 COMPANHIAS COM MAIS VÔOS INTERNACIONAIS
SELECT * FROM (
SELECT v.cia_aerea AS Companhia, COUNT(*) As Voos_Internacionais
FROM voo v JOIN voos_br vbr 
ON(vbr.id_voo = v.id_voo AND vbr.id_aero_origem = v.id_aero_origem
    AND vbr.id_aero_destino = v.id_aero_destino)
WHERE vbr.situacao_voo = 'Realizado'
AND UPPER(v.cod_tp_linha) LIKE '%INTERNAC%'
GROUP BY v.cia_aerea
ORDER BY 2 DESC) rank5
WHERE rownum <= 5;

-- transformando em procedure
CREATE OR REPLACE PROCEDURE ranking_cia( vsituacao IN voos_br.situacao_voo%TYPE,
                    vlinha IN voo.cod_tp_linha%TYPE, vrank IN SMALLINT)
IS CURSOR ranking IS
SELECT * FROM (
        SELECT v.cia_aerea AS Companhia, COUNT(*) As Voos_Internacionais
        FROM voo v JOIN voos_br vbr 
        ON(vbr.id_voo = v.id_voo AND vbr.id_aero_origem = v.id_aero_origem
            AND vbr.id_aero_destino = v.id_aero_destino)
        WHERE UPPER(vbr.situacao_voo) LIKE '%'||UPPER(vsituacao)||'%'
        AND UPPER(v.cod_tp_linha) LIKE '%'||UPPER(vlinha)||'%'
        GROUP BY v.cia_aerea
        ORDER BY 2 DESC) rankcialinha
        WHERE rownum <= vrank;
BEGIN
FOR j in ranking LOOP
DBMS_OUTPUT.PUT_LINE(RPAD(RTRIM(j.Companhia),40, ' ')||j.Voos_Internacionais);
END LOOP;
END;

BEGIN
ranking_cia('real', 'inter',10);
END;


/**************************************************************************
***************************************************************************
  Aula 20 de Setembro e Correção da Atividade 3
****************************************************************************
****************************************************************************/


/*********************************************************
Atividade 03: Utilizando a linguagem PL/SQL e SQL :
1 – Crie um procedimento que mostre a quantidade de vôos de origem e destino para cada aeroporto no formato :
Aeroporto             Qtde Origem                Qtde destino
Guarulhos                100432                      54987  ***/
CREATE OR REPLACE PROCEDURE voo_aeroporto ( vaero IN aeroporto.aeroporto%TYPE)
IS
vdest SMALLINT := 0 ;
vori SMALLINT := 0 ;
vnome aeroporto.aeroporto%TYPE ;
BEGIN
SELECT a.aeroporto INTO vnome FROM aeroporto a
WHERE UPPER(a.aeroporto) LIKE '%'||UPPER(vaero)||'%' ;
SELECT COUNT(*) INTO vori
FROM aeroporto ao , voos_br vbr
WHERE ao.id_aero = vbr.id_aero_origem
AND UPPER(ao.aeroporto) LIKE '%'||UPPER(vaero)||'%'
GROUP BY ao.aeroporto ;
SELECT COUNT(*) INTO vdest
FROM aeroporto ad , voos_br vbr
WHERE ad.id_aero = vbr.id_aero_destino
AND UPPER(ad.aeroporto) LIKE '%'||UPPER(vaero)||'%'
GROUP BY ad.aeroporto ;
DBMS_OUTPUT.PUT_LINE ( 'Aeroporto                                       Qtde Origem   Qtde destino');
DBMS_OUTPUT.PUT_LINE ( RPAD(vnome, 35, ' ')||RPAD(TO_CHAR( vori),15,' ')||TO_CHAR(vdest));
EXCEPTION
WHEN NO_DATA_FOUND THEN
DBMS_OUTPUT.PUT_LINE ( 'Dados não encontrados !!!') ;
END ;

-- executando
BEGIN
voo_aeroporto( 'jaguaruna') ;
END ;

SELECT a.aeroporto FROM aeroporto a
WHERE UPPER(a.aeroporto) LIKE '%'||'GUARU'||'%' ;

/*****
2 – Crie um procedimento para mostrar um ranking ( passar a qtde de cidades) das cidades
indicando se o vôo é de origem ou destino para um determinado ano, no formato:
Ranking      Cidade  - Origem   Ano  : 2017             Qtde Vôos
1                  São Paulo                                                       23890
2                  Rio de Janeiro                                               19654
.............................................................................
7                   Miami                                                               3271   ***/
CREATE OR REPLACE PROCEDURE rank_cidade ( vtipo IN CHAR, vano IN SMALLINT, vrank IN SMALLINT)
IS
CURSOR rcidades IS
SELECT * FROM ( 
SELECT l.cidade, COUNT(*) AS qtdevoos
FROM localidade l JOIN aeroporto a ON ( l.id_local = a.id_local)
JOIN voos_br vbr ON ( DECODE(vtipo, 'O', vbr.id_aero_origem, 'D', vbr.id_aero_destino) = a.id_aero)
WHERE EXTRACT ( YEAR FROM vbr.dthora_partida_prevista) = vano
GROUP BY l.cidade
ORDER BY 2 DESC ) rankcity
WHERE ROWNUM <= vrank ;
vi SMALLINT := 0 ;
vtipo2 CHAR(10) ;
BEGIN
SELECT DECODE(vtipo, 'O', 'Origem','D', 'Destino') INTO vtipo2 FROM dual ;
DBMS_OUTPUT.PUT_LINE ( 'Ranking     Cidade -'||vtipo2||'  Ano: '||
TO_CHAR(vano)||'       Qtde de Vôos') ;
FOR k IN rcidades LOOP
vi := vi + 1 ;
DBMS_OUTPUT.PUT_LINE (RPAD(TO_CHAR(vi), 15, ' ')|| RPAD(k.cidade, 30, ' ')||k.qtdevoos) ;
END LOOP; 
END ;

BEGIN
rank_cidade ( 'O', 2017, 10) ;
END ;

/****
3 – Crie uma função que retorne a quantidade de km voados
por uma determinada companhia aérea num determinado mês e ano. 
Por exemplo, a companhia TAM em 05 de 2016.
****/
CREATE OR REPLACE FUNCTION km_voados ( vcia IN voo.cia_aerea%TYPE,
vmes IN SMALLINT, vano IN SMALLINT) 
RETURN INTEGER IS
vsoma INTEGER := 0 ;
vdist SMALLINT := 0 ;
vteste SMALLINT := 2;
BEGIN
--RAISE_APPLICATION_ERROR( -20000, 'Companhia deve ser preenchida !') ;
SELECT 1 INTO vteste FROM dual 
      WHERE EXISTS (SELECT id_voo FROM voos_br vbr 
      WHERE EXTRACT(YEAR FROM vbr.dthora_partida_prevista) = vano) ;
IF vcia IS NULL THEN
DBMS_OUTPUT.PUT_LINE ( 'Erro') ;
-- RAISE_APPLICATION_ERROR( -20000, 'Companhia deve ser preenchida !') ;
END IF;
IF vmes NOT BETWEEN 1 AND 12 THEN
RAISE_APPLICATION_ERROR( -20001, 'Mês no intervalo entre 1 e 12') ;
END IF;
IF vteste <> 1 THEN 
RAISE_APPLICATION_ERROR( -20002, 'Não encontrado vôo para este ano !') ;   
END IF; 
SELECT SUM(v.distancia) INTO vsoma
FROM voos_br vbr, voo v
WHERE vbr.id_voo = v.id_voo AND vbr.id_aero_origem = v.id_aero_origem
              AND vbr.id_aero_destino = v.id_aero_destino
              AND UPPER(v.cia_aerea) LIKE '%'||UPPER(vcia)||'%'
              AND EXTRACT ( MONTH FROM vbr.dthora_partida_prevista) = vmes
              AND EXTRACT ( YEAR FROM vbr.dthora_partida_prevista) = vano;
--DBMS_OUTPUT.PUT_LINE ( soma) ;
RETURN NVL(vsoma,0) ;
END;
-- testando
SELECT km_voados (null, 18, 2012) FROM dual ;

SELECT km_voados ('azul', 11, 2017) FROM dual ;

SELECT 1 
FROM dual 
WHERE EXISTS (SELECT id_voo FROM voos_br vbr WHERE EXTRACT(YEAR FROM vbr.dthora_partida_prevista) = 2015) 

/******************************************
Aula 20/setembro - Funções analíticas
******************************************/

/**** RANK 
A função analítica RANK tem como objetivo retornar a classificação de
cada linha de um conjunto de resultados ****/
SELECT * FROM ( 
SELECT l.cidade, COUNT(*) AS qtdevoos,
RANK() OVER( ORDER BY COUNT(*) DESC ) AS rkg 
FROM localidade l JOIN aeroporto a ON ( l.id_local = a.id_local)
JOIN voos_br vbr ON ( vbr.id_aero_origem = a.id_aero)
WHERE EXTRACT ( YEAR FROM vbr.dthora_partida_prevista) = 2017
GROUP BY l.cidade ) city
WHERE city.rkg <= 3 ;

-- quebrando por mês e mostrando os 5 mais de cada mês
-- se houver empate não considera e mostra somente 5
SELECT * FROM ( 
SELECT l.cidade, EXTRACT(MONTH FROM vbr.dthora_partida_prevista) AS Mes , COUNT(*) AS qtdevoos,
RANK() OVER( PARTITION BY EXTRACT(MONTH FROM vbr.dthora_partida_prevista) ORDER BY COUNT(*) DESC ) AS rkg 
FROM localidade l JOIN aeroporto a ON ( l.id_local = a.id_local)
JOIN voos_br vbr ON ( vbr.id_aero_origem = a.id_aero)
WHERE EXTRACT ( YEAR FROM vbr.dthora_partida_prevista) = 2017
GROUP BY l.cidade, EXTRACT(MONTH FROM vbr.dthora_partida_prevista) ) city
WHERE city.rkg <= 5 ;

/****
A função analítica DENSE_RANK age da mesma forma que a função RANK,
porém com a diferença nos valores de classificação do rank. Os valores
gerados serão consecutivos, mas os valores duplicados ainda continuarão
com rank repetidos. *****/
SELECT * FROM ( 
SELECT l.cidade, EXTRACT(MONTH FROM vbr.dthora_partida_prevista) AS Mes , COUNT(*) AS qtdevoos,
DENSE_RANK() OVER( PARTITION BY EXTRACT(MONTH FROM vbr.dthora_partida_prevista) ORDER BY COUNT(*) DESC ) AS rkg 
FROM localidade l JOIN aeroporto a ON ( l.id_local = a.id_local)
JOIN voos_br vbr ON ( vbr.id_aero_origem = a.id_aero)
WHERE EXTRACT ( YEAR FROM vbr.dthora_partida_prevista) = 2017
GROUP BY l.cidade, EXTRACT(MONTH FROM vbr.dthora_partida_prevista) ) city
WHERE city.rkg = 1 OR city.rkg = 10 ;



/**** LEAD e LAG
LAG tem como objetivo acessar os dados de uma linha
anterior a partir da linha atual retornada e LEAD a próxima linha ****/
SELECT id_voo , dthora_partida_prevista, proximo_voo, Proximo_após_proximo
       FROM ( SELECT id_voo, dthora_partida_prevista,
                  LEAD(id_voo, 1, 0 ) OVER (ORDER BY dthora_partida_prevista) AS proximo_voo,
                  LEAD(id_voo, 2, 0 ) OVER (ORDER BY dthora_partida_prevista) AS Proximo_após_proximo
                  FROM voos_br ) 
ORDER BY dthora_partida_prevista ;

-- próxima e anterior
SELECT id_voo , dthora_partida_prevista,  voo_anterior, proximo_voo
       FROM ( SELECT id_voo, dthora_partida_prevista,
                  LEAD(id_voo) OVER (ORDER BY dthora_partida_prevista) AS proximo_voo,
                  LAG(id_voo) OVER (ORDER BY dthora_partida_prevista) AS voo_anterior
                   FROM voos_br ) 
ORDER BY dthora_partida_prevista ;

SELECT voo, partida, cia,  cia_anterior, DECODE( cia, cia_anterior, 'MESMA CIA', 'OUTRA CIA')  "Anterior",
             proximo_cia, DECODE( cia, proximo_cia, 'MESMA CIA', 'OUTRA CIA')  "Próxima"
      FROM ( SELECT vbr.id_voo AS voo, vbr.dthora_partida_prevista AS partida, 
                     v.cia_aerea AS cia,
                  LEAD(v.cia_aerea) OVER (ORDER BY vbr.dthora_partida_prevista) AS proximo_cia,
                  LAG(v.cia_aerea) OVER (ORDER BY vbr.dthora_partida_prevista) AS cia_anterior
                   FROM voos_br vbr JOIN voo v
                   ON ( vbr.id_voo = v.id_voo AND vbr.id_aero_origem = v.id_aero_origem
                          AND vbr.id_aero_destino = v.id_aero_destino) ) 
ORDER BY partida ;


/*********************************************************************************************************************************
TENTATIVAS DE FAZER AS ATIVIDADE 4 POR NÓS
************************************************************************************************************************************/



CREATE OR REPLACE PROCEDURE rank1 (comp IN VARCHAR, mes IN NUMBER, ano IN NUMBER)
IS 
CURSOR componente IS
    SELECT retorno.id_voo, retorno.dia, retorno.hora, retorno.rkg, retorno.id_proximo, retorno.data_proximo 
    FROM(
        SELECT v.id_voo, TO_CHAR(EXTRACT (DAY FROM vbr.dthora_partida_prevista)) AS dia, 
        TO_CHAR(EXTRACT (HOUR FROM vbr.dthora_partida_prevista)) AS hora, 
        RANK() OVER(PARTITION BY v.cia_aerea ORDER BY vbr.dthora_partida_prevista ) AS rkg, 
        LEAD(vbr.dthora_partida_prevista) OVER (ORDER BY vbr.dthora_partida_prevista) AS data_proximo,
        LEAD(vbr.id_voo) OVER (ORDER BY vbr.dthora_partida_prevista) AS id_proximo,
        vbr.dthora_partida_prevista as tdlinha
        FROM voo v, voos_br vbr
        WHERE UPPER(v.cia_aerea) LIKE '%'||UPPER(comp)||'%'
        AND (v.id_voo = vbr.id_voo AND v.id_aero_origem = vbr.id_aero_origem AND v.id_aero_destino = vbr.id_aero_destino)
        AND TO_NUMBER(EXTRACT (YEAR FROM vbr.dthora_partida_prevista)) = ano
        AND TO_NUMBER(EXTRACT (MONTH FROM vbr.dthora_partida_prevista)) = mes
        )  retorno;
    BEGIN
    DBMS_OUTPUT.PUT_LINE('Vôo  Origem-Destino  Data  Hora Partida  Próximo Voo  Intervalo Min');
    FOR i IN componente LOOP
    DBMS_OUTPUT.PUT_LINE(i.id_voo || RPAD('xxx',15,' ') || RPAD(i.dia,15,' ') || RPAD(i.hora,15,' ') || RPAD(i.id_proximo,15,' '));
    END LOOP;
END;

BEGIN
rank1('GOL', 1, 2016);
END;
-- Atividade 4, exercicio 2
CREATE OR REPLACE PROCEDURE rank (vaeroporto IN VARCHAR)
IS
CURSOR componente IS
SELECT * FROM (
    SELECT v.cia_aerea, v.id_voo, v.distancia,
    RANK() OVER( PARTITION BY v.cia_aerea ORDER BY v.distancia DESC ) AS rkg 
    FROM aeroporto ae, voo v
    WHERE UPPER(ae.aeroporto)  LIKE  '%'||UPPER(vaeroporto)||'%'
    AND ae.id_aero = v.id_aero_origem) aes
    WHERE aes.rkg <= 3 ;
    vnomeaero VARCHAR2(200);
BEGIN
    SELECT ae.aeroporto INTO vnomeaero
    FROM aeroporto ae
    WHERE UPPER(ae.aeroporto) LIKE '%'||UPPER(vaeroporto)||'%' ;
    DBMS_OUTPUT.PUT_LINE('Aeroporto Origem: ' || vnomeaero);
    FOR i IN componente LOOP
        DBMS_OUTPUT.PUT_LINE(i.rkg || RPAD(i.cia_aerea,15,' ') || RPAD(i.id_voo,15,' ') || i.distancia);
    END LOOP;
END;

BEGIN
rank('Guarulho');
END;




SELECT aeroporto
FROM aeroporto ae
WHERE 'ARUB' LIKE '%'||UPPER(ae.aeroporto)||'%';  



/**************************************************************************************************************************
 Atividade Feita Por Nós
*************************************************************************************************************************/

-- Marcos e Franklin Atividade 4, exercicio 2
CREATE OR REPLACE PROCEDURE rank1 (comp IN VARCHAR, mes IN NUMBER, ano IN NUMBER)
IS 
CURSOR componente IS
    SELECT retorno.id_voo, retorno.dia, retorno.hora, retorno.rkg, retorno.id_proximo, retorno.data_proximo, retorno.origem, retorno.destino, (CAST(data_proximo AS DATE) * 1440) - (CAST(tdlinha AS DATE) * 1440) as difMin
    FROM(
        SELECT v.id_voo, TO_CHAR(EXTRACT (DAY FROM vbr.dthora_partida_prevista)) AS dia, 
        TO_CHAR(EXTRACT (HOUR FROM vbr.dthora_partida_prevista)) AS hora, 
        RANK() OVER(PARTITION BY v.cia_aerea ORDER BY vbr.dthora_partida_prevista) AS rkg, 
        LEAD(vbr.dthora_partida_prevista) OVER (ORDER BY vbr.dthora_partida_prevista) AS data_proximo,
        LEAD(vbr.id_voo) OVER (ORDER BY vbr.dthora_partida_prevista) AS id_proximo,
        vbr.dthora_partida_prevista as tdlinha,
		vbr.id_aero_origem as origem,
		vbr.id_aero_destino as destino,
        FROM voo v, voos_br vbr
        WHERE UPPER(v.cia_aerea) LIKE '%'||UPPER(comp)||'%'
        AND (v.id_voo = vbr.id_voo AND v.id_aero_origem = vbr.id_aero_origem AND v.id_aero_destino = vbr.id_aero_destino)
        AND TO_NUMBER(EXTRACT (YEAR FROM vbr.dthora_partida_prevista)) = ano
        AND TO_NUMBER(EXTRACT (MONTH FROM vbr.dthora_partida_prevista)) = mes
        )  retorno;
		vcityori localidade.cidade%TYPE;
		vcitydest localidade.cidade%TYPE;
    BEGIN
    DBMS_OUTPUT.PUT_LINE('Vôo  Origem-Destino  Data  Hora Partida  Próximo Voo  Intervalo Min');
    FOR i IN componente 
		SELECT l.cidade INTO vcityori
		FROM aeroporto ae
		WHERE i.origem = ae.id_aero
		AND ae.id_local = l.id_local;
		
		SELECT l.cidade INTO vcitydest
		FROM aeroporto ae
		WHERE i.destino = ae.id_aero
		AND ae.id_local = l.id_local;
    DBMS_OUTPUT.PUT_LINE(i.id_voo || RPAD(vcityori||'-'||vcitydest,15,' ') || RPAD(i.dia,15,' ') || RPAD(i.hora,15,' ') || RPAD(i.id_proximo,15,' ') || i.difMin);
    END LOOP;
END;








/*************************************
daqui pra baixo só rascunho para verificar as sujeiras dos dados
********************************************/

SELECT RTRIM(voos) AS voo, rowid AS idlinha,
   TO_NUMBER(SUBSTR(longorig,1,12),'999.99999999') AS longori, 
   TO_NUMBER(SUBSTR(latorig,1,12),'999.99999999') AS latiori,  
   TO_NUMBER(SUBSTR(longdest,1,12),'999.99999999') AS longdest,
   TO_NUMBER(SUBSTR(latdest,1,12),'999.99999999') AS latidest, 
   TO_TIMESTAMP ( DECODE( RTRIM(partida_prevista), 'NA', '0001-01-01T00:00:00Z', partida_prevista ), 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS part_prev, 
   TO_TIMESTAMP (DECODE( RTRIM(partida_real), 'NA', '0001-01-01T00:00:00Z', partida_real ) , 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS part_real,
   TO_TIMESTAMP ( DECODE( RTRIM(chegada_prevista), 'NA', '0001-01-01T00:00:00Z', chegada_prevista ), 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS cheg_prev,  
   TO_TIMESTAMP ( DECODE( RTRIM(chegada_real), 'NA', '0001-01-01T00:00:00Z', chegada_real ), 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS cheg_real,
   RTRIM ( situacao_voo) As situacao,
   RTRIM( codigo_justificativa) AS justificativa,
   LEAD(voos,1,0) OVER (ORDER BY voos) AS next_voo, 
   LAG(voos,1,0) OVER (ORDER BY voos) AS before_voo
   FROM fonte
WHERE rownum < 3805 ;
WHERE rowid = 'AAAG9HAAJAAADicAAa'; 


SELECT RTRIM(voos)||'**'||rowid||'**'||TO_NUMBER(SUBSTR(longorig,1,12),'999.99999999')||'**'|| 
   TO_NUMBER(SUBSTR(latorig,1,12),'999.99999999')||'**'||TO_NUMBER(SUBSTR(longdest,1,12),'999.99999999')||'**'||
   TO_NUMBER(SUBSTR(latdest,1,12),'999.99999999')||'**'|| 
   TO_TIMESTAMP ( DECODE( RTRIM(partida_prevista), 'NA', '0001-01-01T00:00:00Z', partida_prevista ), 'YYYY-MM-DD"T"HH24:MI:SS"Z"')||'**'|| 
   TO_TIMESTAMP (DECODE( RTRIM(partida_real), 'NA', '0001-01-01T00:00:00Z', partida_real ) , 'YYYY-MM-DD"T"HH24:MI:SS"Z"')||'**'||
   TO_TIMESTAMP ( DECODE( RTRIM(chegada_prevista), 'NA', '0001-01-01T00:00:00Z', chegada_prevista ), 'YYYY-MM-DD"T"HH24:MI:SS"Z"')||'**'||  
   TO_TIMESTAMP ( DECODE( RTRIM(chegada_real), 'NA', '0001-01-01T00:00:00Z', chegada_real ), 'YYYY-MM-DD"T"HH24:MI:SS"Z"')||'**'||
   RTRIM ( situacao_voo)||'**'||
   RTRIM( codigo_justificativa),
   LEAD(voos,1,0) OVER (ORDER BY voos) AS next_voo, 
   LAG(voos,1,0) OVER (ORDER BY voos) AS before_voo
   FROM fonte
WHERE rownum < 3806 ;
WHERE rowid = 'AAAG9HAAJAAADicAAa'; 


SELECT EMPNO, ENAME, SALARY,
                LEAD(SALARY, 1, 0) OVER (ORDER BY SALARY) AS NEXT_SAL,
FROM EMPLOYEES;

SELECT * FROM voos_br ;


/*
SQL> SELECT DEPTNO ,
  2         NEXT_DEPTNO ,
  3         DECODE(DEPTNO,NEXT_DEPTNO,'MATCHING','NOT MATCHING')  "COMMENT"
  4    FROM (SELECT DEPTNO ,
  5                 LEAD(DEPTNO) OVER (ORDER BY DEPTNO) AS NEXT_DEPTNO
  6            FROM EMP
  7           ORDER BY DEPTNO);

    DEPTNO NEXT_DEPTNO COMMENT
---------- ----------- ------------
        10          10 MATCHING
        10          10 MATCHING
        10          20 NOT MATCHING
        20          20 MATCHING
        20          20 MATCHING
        20          20 MATCHING
        20          20 MATCHING
        20          30 NOT MATCHING
        30          30 MATCHING
        30          30 MATCHING
        30          30 MATCHING
        30          30 MATCHING
        30          30 MATCHING
        30          50 NOT MATCHING
        50             NOT MATCHING
*/

SELECT RTRIM(voos) AS voo, 
   TO_NUMBER(SUBSTR(longorig,1,12),'999.99999999') AS longori, 
   TO_NUMBER(SUBSTR(latorig,1,12),'999.99999999') AS latiori,  
   TO_NUMBER(SUBSTR(longdest,1,12),'999.99999999') AS longdest,
   TO_NUMBER(SUBSTR(latdest,1,12),'999.99999999') AS latidest, 
   TO_TIMESTAMP ( DECODE( RTRIM(partida_prevista), 'NA', '0001-01-01T00:00:00Z', partida_prevista ), 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS part_prev, 
   TO_TIMESTAMP (DECODE( RTRIM(partida_real), 'NA', '0001-01-01T00:00:00Z', partida_real ) , 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS part_real,
   TO_TIMESTAMP ( DECODE( RTRIM(chegada_prevista), 'NA', '0001-01-01T00:00:00Z', chegada_prevista ), 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS cheg_prev,  
   TO_TIMESTAMP ( DECODE( RTRIM(chegada_real), 'NA', '0001-01-01T00:00:00Z', chegada_real ), 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS cheg_real,
   RTRIM ( situacao_voo) As situacao,
   RTRIM( codigo_justificativa) AS justificativa,
   rowid AS idlinha FROM fonte
   WHERE rownum < 1000000 ;
   
   SELECT RTRIM(voos) AS voo, 
   TO_TIMESTAMP ( DECODE( RTRIM(partida_real), 'NA', '0001-01-01T00:00:00Z', partida_real ), 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS part_real,
   RTRIM ( situacao_voo) As situacao,
   RTRIM( codigo_justificativa) AS justificativa,
   rowid AS idlinha FROM fonte
   WHERE rownum < 105
   
   
   
   
   SELECT RTRIM(voos) ||'-'||partida_prevista||'//'||partida_real||'//'||chegada_prevista||'//'||chegada_real||'***'||RTRIM ( situacao_voo)
   ||'***'||RTRIM( codigo_justificativa)||'[]'||rowid
   FROM fonte
   WHERE rownum < 3805
   
   SELECT COUNT(*) FROM fonte
   WHERE RTRIM(partida_real) = 'NA' ;
   
   SELECT DISTINCT partida_real FROM fonte
   ORDER BY 1 DESC ;
   
   SELECT partida_real,
   CASE
     WHEN regexp_like ( partida_real, '[0-9]') THEN 'DATE'
     WHEN regexp_like ( partida_real, '[NA]') THEN 'STRING'
    END 
   FROM fonte ;
   

SELECT voos , codigo_tipo_linha, proximo_voo ,
       DECODE(voos,proximo_voo,'COINCIDE','NAO COINCIDE')  "Comentario"
      FROM ( SELECT voos, codigo_tipo_linha,
                  LEAD(voos) OVER (ORDER BY voos) AS proximo_voo
                   FROM fonte ) 
--WHERE codigo_tipo_linha <> proximo.codigo_tipo_linha  
ORDER BY voos ;


SELECT COUNT(*) FROM 
(SELECT TO_TIMESTAMP ( partida_prevista, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') FROM fonte) teste ;
SELECT COUNT(*) FROM 
(SELECT TO_TIMESTAMP ( partida_real, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') FROM fonte) teste ;
SELECT COUNT(*) FROM 
(SELECT TO_TIMESTAMP ( chegada_prevista, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') FROM fonte) teste ;
SELECT COUNT(*) FROM 
(SELECT TO_TIMESTAMP ( chegada_real, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') FROM fonte) teste ;
WHERE rownum <= 2600000 ;

-- verificando qtde de combinações
SELECT COUNT(*) FROM (
SELECT DISTINCT(f1.id_voo) , f1.cod_tp_linha, 
f1.id_aero_origem, f1.id_aero_destino
FROM fontelimpa f1 ) teste ;
ORDER BY 1 ;

-- Calcula a distância entre dois pontos lat1,lon1 and lat2,lon2
 -- Usa o raio da Terra em kilometros ou milhas como um argumento
 -- Raio Típico :  3963.0 (milhas) (Default se nenhum valor for especificado)
 --                      6387.7 (km)
 -- Note: NVL function is used on all variables to replace NULL values with 0 (zero).
 -- For enquiries, please contact sales@geodatasource.com
 -- Official Web site: https://www.geodatasource.com
 --Thanks to Bill Dykstra for contributing the source code.
 -- GeoDataSource.com (C) All Rights Reserved 2017
 CREATE OR REPLACE FUNCTION distancia (Lat1 IN NUMBER,
                                     Lon1 IN NUMBER,
                                     Lat2 IN NUMBER,
                                     Lon2 IN NUMBER,
                                     Radius IN NUMBER DEFAULT 6387.7) RETURN NUMBER IS
 -- Convert degrees to radians
 Grau_para_Radiano NUMBER := 57.29577951;

BEGIN
  RETURN(NVL(Radius,0) * ACOS((sin(NVL(Lat1,0) /  Grau_para_Radiano ) * SIN(NVL(Lat2,0) /  Grau_para_Radiano)) +
        (COS(NVL(Lat1,0) /  Grau_para_Radiano) * COS(NVL(Lat2,0) /  Grau_para_Radiano) *
         COS(NVL(Lon2,0) /  Grau_para_Radiano - NVL(Lon1,0)/  Grau_para_Radiano)))) ;
         --*1.609344 ;
END;

SELECT distancia (-22.81, -43.24, -14.81, -39.03) FROM dual ;
