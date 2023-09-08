from flask import Flask, render_template, request
from google.cloud import secretmanager
from flask import Flask, render_template, request, jsonify, url_for
import os
import asyncio 
from langchain.chains.summarize import load_summarize_chain
from langchain.docstore.document import Document
from langchain.llms import VertexAI
from langchain import PromptTemplate, LLMChain
from IPython.display import display, Markdown
from google.cloud import aiplatform
from langchain.embeddings import VertexAIEmbeddings
from google.cloud.sql.connector import Connector
from pgvector.asyncpg import register_vector
import nest_asyncio
import markdown
nest_asyncio.apply()
import sqlalchemy
from sqlalchemy import insert, Table, Column, VARCHAR, TEXT, NUMERIC, MetaData, select, INTEGER, ForeignKey
from google.cloud.alloydb.connector import Connector
from pgvector.sqlalchemy import Vector
from sqlalchemy.orm import declarative_base, mapped_column, Session
import pandas as pd
from sqlalchemy import bindparam

app = Flask(__name__)

def get_secret_data(project_id, secret_id, version_id):
    client = secretmanager.SecretManagerServiceClient()
    secret_detail = f"projects/{project_id}/secrets/{secret_id}/versions/{version_id}"
    response = client.access_secret_version(request={"name": secret_detail})
    data = response.payload.data.decode("UTF-8")
    return data

@app.route('/')
def index():
    return render_template('index.html')

# Define the route for the about page
@app.route('/about')
def about():
    return render_template('about.html')

@app.route('/chat', methods=['POST'])
def chat():
    user_query = request.form['user_query']

    try:
        response = asyncio.run(main(user_query))
        response_text = markdown.markdown(response.data)
        return jsonify({'response': response_text})
        #return response_text
    except Exception as e:
        return jsonify({'error': str(e)})

async def main(user_query):
    response = await run_product_info_flow(user_query)
    # Print the response
    print(response)
    return response


async def run_product_info_flow(user_query):
    # Create an event loop
    loop = asyncio.get_event_loop()

    # Run the get_product_info function within the event loop
    matches = loop.run_until_complete(get_product_info(user_query))
    llm = VertexAI()

    map_prompt_template = """
              You will be given a detailed description of a toy product.
              This description is enclosed in triple backticks (```).
              Using this description only, extract the name of the toy,
              the price of the toy and its features.

              ```{text}```
              SUMMARY:
              """
    map_prompt = PromptTemplate(template=map_prompt_template, input_variables=["text"])

    combine_prompt_template = """
                        You will be given a detailed description different toy products
                        enclosed in triple backticks (```) and a question enclosed in
                        double backticks(``).
                        Select one toy that is most relevant to answer the question.
                        Using that selected toy description, answer the following
                        question in as much detail as possible.
                        You should only use the information in the description.
                        Your answer should include the name of the toy, the price of the toy
                        and its features. Your answer should be less than 400 words.
                        Your answer should be in html in a numbered list format.


                        Description:
                        ```{text}```


                        Question:
                        ``{user_query}``


                        Answer:
                        """
    combine_prompt = PromptTemplate(
        template=combine_prompt_template, input_variables=["text", "user_query"]
    )

    docs = [Document(page_content=t) for t in matches]
    chain = load_summarize_chain(
        llm, chain_type="map_reduce", map_prompt=map_prompt, combine_prompt=combine_prompt
    )

    answer = chain.run(
        {
            "input_documents": docs,
            "user_query": user_query,
        }
    )
    #print(Markdown(answer))
    return Markdown(answer)

async def get_product_info(user_query):
    project_id = "genai-for-alloydb"
    region = "us-central1"  # @param {type:"string"}
    cluster_name = "genai-for-alloydb-cluster" # @param {type:"string"}
    instance_name = "genai-for-alloydb-instance"  # @param {type:"string"}
    database_name = "retail"  # @param {type:"string"}
    network = "default" # @param {type:"string"}
    database_user=get_secret_data('genai-for-alloydb','GenAI_for_AlloyDB_database_username',1)
    database_password=get_secret_data('genai-for-alloydb','GenAI_for_AlloyDB_database_password',1)
    # Initialize Vertex AI
    matches = []
    aiplatform.init(project=f"{project_id}", location=f"{region}")

    embeddings_service = VertexAIEmbeddings()
    qe = embeddings_service.embed_query(user_query)

    # initialize Connector object
    connector = Connector()
    Base = declarative_base()

    class Product_embeddings(Base):
        __tablename__ = 'product_embeddings'
        product_id = mapped_column(VARCHAR(1024),ForeignKey("products.product_id"),nullable=False, primary_key=True)
        content = mapped_column(TEXT, primary_key=True )
        embedding = mapped_column(Vector(768))

    meta=Base.metadata
# function to return the database connection
    def getconn():
        conn = connector.connect(
            f"projects/{project_id}/locations/{region}/clusters/{cluster_name}/instances/{instance_name}",
            "pg8000",
            user=database_user,
            password=database_password,
            db=database_name
        )
        return conn
    
    # create connection pool {engine}
    engine = sqlalchemy.create_engine(
        "postgresql+pg8000://",
        creator=getconn,
    )
    print ("engine")
    try:
        product_embedding = Table("product_embeddings", meta, autoload_with=engine)
    except:
        print("No product_embeddings table")

    try:
        products = Table("products", meta, autoload_with=engine)
    except:
        print("No products table")
    print ("enginesssss")
    conn=engine.connect()
    # Configurations
    similarity_threshold = 0.7
    num_matches = 5
    stmt=sqlalchemy.text("""
                                WITH vector_matches AS (
                                SELECT product_id, 1 - (embedding <=> :qe) AS similarity
                                FROM product_embeddings
                                WHERE 1 - (embedding <=> :qe) > :similarity_threshold
                                ORDER BY similarity DESC
                                LIMIT :num_matches
                                )
                                SELECT product_name, list_price, description FROM products
                                WHERE product_id IN (SELECT product_id FROM vector_matches)
                        """)

    stmt = stmt.bindparams(
        bindparam('num_matches', type_=INTEGER),
        bindparam('similarity_threshold', type_=NUMERIC),
        bindparam('qe', type_=Vector(768))
    )
                    
    results = conn.execute(stmt, parameters={'qe':qe, 'similarity_threshold':similarity_threshold, 'num_matches':num_matches}).fetchall()


    conn.commit()
    conn.close()
    connector.close()

    if len(results) == 0:
        raise Exception("Sorry, didn't found any toy with this description.") 
        
    matches=[]                    
    # for r in results:
    #     # Collect the description for all the matched similar toy products.
    #     matches.append(
    #         {
    #             "product_name": r[0],
    #             "description": r[2],
    #             "list_price": round(r[1], 2)
    #         }
    #     )

        
    for r in results:
        # Collect the description for all the matched similar toy products.
        matches.append(
            f"""The name of the toy is {r[0]}.
                    The price of the toy is ${round(r[1], 2)}.
                    Its description is below:
                    {r[2]}."""
        )
        
    return(matches)

if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))