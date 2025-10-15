import os
import sys
import argparse
from google import genai
import chromadb

# --- 1. SETUP ---
# NOTE: This uses a simplified in-memory ChromaDB instance for demonstration.
# In a real pipeline, you'd use a persistent database or a dedicated service.
DB_PATH = "/tmp/chroma_db_cache"
COLLECTION_NAME = "code_snippets"
SNIPPET_SIZE = 500  # Max chunk size for embedding

def get_db_client():
    """Initializes ChromaDB client using the recommended PersistentClient."""
    # MODIFIED: Use PersistentClient for modern initialization
    client = chromadb.PersistentClient(path=DB_PATH)
    return client.get_or_create_collection(name=COLLECTION_NAME)

def get_code_snippets(file_path):
    """Simple function chunker."""
    with open(file_path, 'r') as f:
        content = f.read()
        # Simple chunking by SNIPPET_SIZE for demonstration. 
        # For C++, you'd use a parser to chunk by function/class.
        for i in range(0, len(content), SNIPPET_SIZE):
            yield content[i:i + SNIPPET_SIZE]

# --- 2. INDEXING ---
def index_codebase(client, context_files):
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
        client.add(
            documents=documents,
            metadatas=metadatas,
            ids=ids
        )
        print(f"Indexed {client.count()} total snippets.")
    else:
        print("No documents to index.")

# --- 3. RETRIEVAL ---
def retrieve_context(client, query):
    """Performs a similarity search using the query."""
    print(f"Searching for context related to: {query[:50]}...")
    
    # ChromaDB automatically uses the default embedding function (sentence-transformers)
    results = client.query(
        query_texts=[query],
        n_results=3  # Retrieve top 3 most relevant snippets
    )

    context = []
    if results and results['documents']:
        for docs, metadatas in zip(results['documents'], results['metadatas']):
            for doc, metadata in zip(docs, metadatas):
                context.append(f"## Source: {metadata['source']}\n{doc}\n")
    
    return "\n---\n".join(context)


def main():
    parser = argparse.ArgumentParser(description="RAG Code Context Finder")
    parser.add_argument('mode', choices=['index', 'retrieve'], help='Operation mode.')
    parser.add_argument('--files', nargs='*', help='List of files to index (for index mode).')
    parser.add_argument('--query', help='Query string (LCOV miss list) for retrieval mode.')
    parser.add_argument('--output', help='File to write retrieved context (for retrieve mode).')

    args = parser.parse_args()
    
    # Ensure GEMINI_API_KEY is set in the environment
    if not os.getenv("GEMINI_API_KEY"):
        print("Error: GEMINI_API_KEY environment variable is not set.", file=sys.stderr)
        sys.exit(1)

    # Initialize client (uses default embedding model which is sufficient for RAG)
    client = get_db_client()

    # MODIFIED: Get the persistent client instance separately
    try:
        persistent_client = chromadb.PersistentClient(path=DB_PATH)
        client = persistent_client.get_or_create_collection(name=COLLECTION_NAME)
    except Exception as e:
        print(f"Error initializing ChromaDB client: {e}", file=sys.stderr)
        sys.exit(1)

    if args.mode == 'index':
        if not args.files:
            print("Error: --files must be provided for index mode.", file=sys.stderr)
            sys.exit(1)
            
        index_codebase(client, args.files)
        
        # CORRECTED: REMOVE THE persist() CALL. Persistence is handled automatically or implicitly by PersistentClient.
        # persistent_client.persist() 
        # print("Database persisted successfully.") 
        # We can just exit cleanly.

    elif args.mode == 'retrieve':
        if not args.query or not args.output:
            print("Error: --query and --output must be provided for retrieve mode.", file=sys.stderr)
            sys.exit(1)
        
        retrieved_context = retrieve_context(client, args.query)
        
        with open(args.output, 'w') as f:
            f.write(retrieved_context)

if __name__ == "__main__":
    main()