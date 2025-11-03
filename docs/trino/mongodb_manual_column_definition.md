# Mapeamento Manual de Colunas de Coleções

## Problema

O Trino pode não reconhecer automaticamente todas as colunas da sua coleção MongoDB durante a prospecção inicial. Isso acontece quando:

- Os campos não aparecem em todos os documentos da coleção
- A amostra inicial lida pelo Trino não contém determinados campos
- Há tipos de dados complexos ou aninhados que precisam de definição explícita
- A coleção possui schema inconsistente entre documentos

## Solução: Definição Manual de Schema

Para forçar o Trino a reconhecer campos específicos, você pode definir manualmente o schema da coleção através da coleção especial `_schemas` no MongoDB.

## Passo a Passo

### 1. Acesse a coleção `_schemas`

Localize a coleção `_schemas` no seu banco de dados MongoDB (ou o nome que você definiu na variável `MONGODB_SCHEMA_COLLECTION` no arquivo `.env`).

Esta coleção especial armazena as definições de schema que o Trino usa para mapear as coleções MongoDB.

### 2. Encontre o documento da sua coleção

Procure o documento onde o campo `table` corresponde ao nome da coleção que você deseja modificar.

**Exemplo:**
```json
{
  "_id": ObjectId("..."),
  "table": "minha_colecao",
  "fields": [...]
}
```

### 3. Edite o array `fields`

Adicione ou modifique os campos no array `fields`, especificando o nome e o tipo de cada coluna que deseja expor ao Trino.

**⚠️ IMPORTANTE:** Faça backup do documento antes de editar!

**Exemplo de definição completa:**
```json
{
  "table": "pedidos",
  "fields": [
    { "name": "_id", "type": "objectid" },
    { "name": "customer_id", "type": "varchar" },
    { "name": "amount", "type": "double" },
    { "name": "paid", "type": "boolean" },
    { "name": "created_at", "type": "timestamp" },
    { "name": "status", "type": "varchar" },
    { "name": "items", "type": "array(row(product_id varchar, qty bigint, price double))" },
    { "name": "shipping_address", "type": "row(street varchar, city varchar, zipcode varchar)" },
    { "name": "metadata", "type": "map(varchar, varchar)" }
  ]
}
```

### 4. Salve as alterações

Salve o documento modificado na coleção `_schemas`.

### 5. Force o Trino a recarregar o schema

Após atualizar `_schemas`, o Trino precisa recarregar a metadata. Escolha uma das opções abaixo:

**Opção 1: Reiniciar o container (RECOMENDADO)**

Forma mais simples e confiável de garantir que todas as configurações sejam recarregadas:

```sh
docker compose restart trino-kidopi
```

**Vantagens:**
- Garante limpeza completa de todos os caches
- Recarrega todas as configurações
- Mais confiável

**Desvantagens:**
- Interrompe o serviço temporariamente (~30-60 segundos)
- Todas as queries em execução são canceladas

**Opção 2: Limpar cache via CLI (AVANÇADO)**

Se o seu container possui o Trino CLI e você não pode interromper o serviço, tente limpar apenas o cache de metadata:

```sh
# Tente este primeiro:
docker compose exec trino-kidopi trino --execute "CALL system.flush_metadata_cache();"

# Ou este (dependendo da versão):
docker compose exec trino-kidopi trino --execute "CALL system.invalidate_metadata_cache();"

# Ou force refresh de um catalog específico:
docker compose exec trino-kidopi trino --execute "CALL system.refresh_metadata('mongodb', 'seu_schema', 'sua_colecao');"
```

**⚠️ Observação:** O comando exato varia entre versões do Trino. Consulte a [documentação oficial](https://trino.io/docs/current/) da sua versão para detalhes.

Se o CLI não estiver disponível no container, use a **Opção 1**.


## Referência de Tipos de Dados

### Mapeamento de Tipos Comuns MongoDB → Trino

| Tipo MongoDB | Tipo Trino | Exemplo |
|-------------|-----------|---------|
| String | `varchar` | `{ "name": "nome", "type": "varchar" }` |
| Int32/Int64/Long | `bigint` | `{ "name": "idade", "type": "bigint" }` |
| Double/Float | `double` | `{ "name": "preco", "type": "double" }` |
| Boolean | `boolean` | `{ "name": "ativo", "type": "boolean" }` |
| Date/ISODate | `timestamp` | `{ "name": "criado_em", "type": "timestamp" }` |
| ObjectId | `objectid` | `{ "name": "_id", "type": "objectid" }` |
| Array simples | `array(tipo)` | `{ "name": "tags", "type": "array(varchar)" }` |
| Array de objetos | `array(row(...))` | `{ "name": "items", "type": "array(row(id varchar, qty bigint))" }` |
| Objeto aninhado | `row(campo tipo, ...)` | `{ "name": "endereco", "type": "row(rua varchar, numero bigint)" }` |
| Map/Dicionário | `map(tipo_chave, tipo_valor)` | `{ "name": "atributos", "type": "map(varchar, varchar)" }` |
---

<sub>Para mais informações sobre os tipos de dados do trino, visite a [documentação oficial](https://trino.io/docs/current/connector/mongodb.html#table-definition-label).</sub>



## Verificação

Após aplicar as mudanças e recarregar o Trino, teste se as colunas estão visíveis:

```sql
-- Ver todas as colunas da tabela
DESCRIBE mongodb.seu_schema.sua_colecao;

-- Testar consulta simples
SELECT * FROM mongodb.seu_schema.sua_colecao LIMIT 5;

-- Testar campos específicos
SELECT 
    customer_id,
    amount,
    paid,
    created_at
FROM mongodb.seu_schema.sua_colecao
LIMIT 10;
```

**Possíveis problemas:**

- **Coluna ainda não aparece:** Verifique se o nome do campo está correto (case-sensitive) e se o tipo de dados está compatível
- **Erro de tipo:** O tipo definido em `_schemas` pode não corresponder aos dados reais. Ajuste conforme necessário
- **Performance lenta:** Tipos complexos (arrays, rows) podem ser mais lentos. Considere filtros adequados