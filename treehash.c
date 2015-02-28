#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <openssl/sha.h>

struct node_sha {
  unsigned char sha[SHA256_DIGEST_LENGTH];
  struct node_sha *next;
};

typedef struct node_sha sha;

size_t min(size_t a, size_t b) {
  return a < b ? a : b;
}

void combine(sha *a, sha *b) {
  SHA256_CTX ctx;
  SHA256_Init(&ctx);
  SHA256_Update(&ctx, a->sha, SHA256_DIGEST_LENGTH);
  SHA256_Update(&ctx, b->sha, SHA256_DIGEST_LENGTH);
  SHA256_Final(a->sha, &ctx);
}

void read_one_meg(unsigned char *buf, int bufsize, unsigned char *sha) {
  size_t mb = 1024 * 1024;
  size_t total_amount_read = 0;
  size_t amount_read = 0;
  size_t to_read;
  int eof = 0;
  SHA256_CTX ctx;
  SHA256_Init(&ctx);
  while(!eof && total_amount_read < mb) {
    to_read = min(mb - total_amount_read, bufsize);
    amount_read = fread(buf, 1, to_read, stdin);
    eof = amount_read != to_read;
    total_amount_read += amount_read;
    SHA256_Update(&ctx, buf, amount_read);
  }
  SHA256_Final(sha, &ctx);
}

void printbuf(unsigned char *buf) {
  int len;
  for (len = 0; len < SHA256_DIGEST_LENGTH; ++len)
    printf("%02x", buf[len]);
  printf("\n");
}

void reduce(sha *head) {
 sha *a, *b;
 while (head->next) {
   a = head;
   while (a && a->next) {
     b = a->next;
     combine(a,b);
     a->next = b->next;
     a = b->next;
     free(b);
   }
 }
}

int stdin_has_data() {
  char c;
  c = fgetc(stdin);
  ungetc(c, stdin);
  return c != EOF;
}

int main(int argc, char **argv) {
  unsigned char buffer[BUFSIZ];
  sha* head;
  sha* cur;
  cur = head = (sha *) calloc(sizeof(sha), 1);
  while (stdin_has_data()) {
    cur->next = (sha *) calloc(sizeof(sha), 1);
    cur = cur->next;
    read_one_meg(buffer, BUFSIZ, cur->sha);
  } 
  reduce(head->next);
  printbuf(head->next->sha);
  return 0;
}
