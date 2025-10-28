import argparse
import os
import sys
from pathlib import Path
from typing import List, Dict

# --- Ollama Imports ---
import ollama
import chromadb
from chromadb.utils import embedding_functions

# --- CONFIGURATION (Customize these) ---
# NOTE: The Ollama server must be running on the Jenkins agent or accessible via this host/port.
OLLAMA_HOST = os.environ.get("OLLAMA_HOST", "http://192.168.1.107:11434") 
EMBEDDING_MODEL_NAME = "nomic-embed-text"  # Ensure this model is pulled in Ollama (e.g., 'ollama pull nomic-embed-text')

DB_PATH = "/tmp/chroma_db_cache"
COLLECTION_NAME = "code_snippets_ollama"
SNIPPET_SIZE = 500  # Max chunk size for embedding
# ----------------------------------------


def get_ollama_ef():
    """Initializes and returns the ChromaDB Embedding Function using Ollama."""
    # MODIFIED: Use the OllamaEmbeddingFunction provided by ChromaDB or a custom one
    # Note: Requires ollama Python package and the Ollama service to be running.
    class OllamaEmbeddingFunction(embedding_functions.EmbeddingFunction):
        def __init__(self, model_name: str, host: str):
            self.model_name = model_name
            self.host = host

        def __call__(self, texts: List[str]) -> List[List[float]]:
            # Connect to Ollama client 
            client = ollama.Client(host=self.host)
            
            # Generate embeddings for the list of texts
            embeddings = []
            for text in texts:
                response = client.embeddings(model=self.model_name, prompt=text)
                embeddings.append(response['embedding'])
            return embeddings

    # Initialize the custom Ollama Embedding Function
    return OllamaEmbeddingFunction(
        model_name=EMBEDDING_MODEL_NAME, 
        host=OLLAMA_HOST
    )


def get_db_client():
    """Initializes ChromaDB client and collection with Ollama embeddings."""
    try:
        # Initialize the custom Ollama Embedding Function
        ollama_ef = get_ollama_ef()
        
        # Initialize PersistentClient
        persistent_client = chromadb.PersistentClient(path=DB_PATH)
        
        # Get or create the collection, setting the Ollama embedding function
        collection = persistent_client.get_or_create_collection(
            name=COLLECTION_NAME,
            embedding_function=ollama_ef
        )
        return collection
        
    except Exception as e:
        print(f"Error initializing ChromaDB or Ollama Embedding Function: {e}", file=sys.stderr)
        # Detailed error if Ollama service is down
        print(f"Ensure Ollama is running and model '{EMBEDDING_MODEL_NAME}' is pulled.", file=sys.stderr)
        sys.exit(1)


def get_code_snippets(file_path: str):
    """Simple function chunker."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            # Simple chunking by SNIPPET_SIZE for demonstration.
            for i in range(0, len(content), SNIPPET_SIZE):
                yield content[i:i + SNIPPET_SIZE]
    except FileNotFoundError:
        print(f"Warning: File not found at {file_path}", file=sys.stderr)
        return


def index_codebase(client: chromadb.Collection, context_files: List[str]):
    """Indexes the files into the ChromaDB collection."""
    print(f"Indexing {len(context_files)} files...")
    
    # We only index if the collection is empty
    if client.count() > 0:
        print("Database already contains data. Skipping indexing.")
        return

    documents = []
    metadatas = []
    ids = []
    doc_id_counter = 0

    for file_path in context_files:
        for snippet in get_code_snippets(file_path):
            documents.append(snippet)
            metadatas.append({"source": file_path})
            ids.append(f"doc_{doc_id_counter}")
            doc_id_counter += 1

    if documents:
        # Client handles embedding generation using the configured Ollama EF
        client.add(
            documents=documents,
            metadatas=metadatas,
            ids=ids
        )
        print(f"Indexed {client.count()} total snippets.")
    else:
        print("No documents to index.")


def retrieve_context(client: chromadb.Collection, query: str) -> str:
    """Performs a similarity search using the query."""
    print(f"Searching for context related to: {query[:50]}...")
    
    # Client uses the configured Ollama EF to embed the query
    results = client.query(
        query_texts=[query],
        n_results=3  # Retrieve top 3 most relevant snippets
    )

    context = []
    if results and results.get('documents'):
        for docs, metadatas in zip(results['documents'], results['metadatas']):
            for doc, metadata in zip(docs, metadatas):
                context.append(f"## Source: {metadata.get('source', 'Unknown')}\n{doc}\n")
    
    return "\n---\n".join(context)


def main():
    parser = argparse.ArgumentParser(description="RAG Code Context Finder for Ollama.")
    parser.add_argument('mode', choices=['index', 'retrieve'], help='Operation mode.')
    parser.add_argument('--files', nargs='*', default=[], help='List of files to index (for index mode).')
    parser.add_argument('--query', help='Query string (LCOV miss list) for retrieval mode.')
    parser.add_argument('--output', help='File to write retrieved context (for retrieve mode).')

    args = parser.parse_args()
    
    # MODIFIED: Removed the check for GEMINI_API_KEY
    
    # Initialize client with Ollama Embedding Function
    client = get_db_client()

    if args.mode == 'index':
        if not args.files:
            print("Error: --files must be provided for index mode.", file=sys.stderr)
            sys.exit(1)
            
        index_codebase(client, args.files)
        
    elif args.mode == 'retrieve':
        if not args.query or not args.output:
            print("Error: --query and --output must be provided for retrieve mode.", file=sys.stderr)
            sys.exit(1)
        
        retrieved_context = retrieve_context(client, args.query)
        
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(retrieved_context)


if __name__ == "__main__":
    main()

