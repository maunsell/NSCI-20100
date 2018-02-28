// Client side C/C++ program to demonstrate Socket programming
#include <stdio.h>
#include <sys/socket.h>
#include <stdlib.h>
#include <netinet/in.h>
#include <string.h>
#include <arpa/inet.h>
#include <sys/ioctl.h>

#define PORT 8080

int main(int argc, char const *argv[])
{
//    struct sockaddr_in address;
    int sock = 0;
    ssize_t valread;
    struct sockaddr_in serv_addr;
//    char hello[] = "Hello from client";
    char buffer[1024] = {0};

    if ((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        printf("\n Socket creation error \n");
        return -1;
    }
    memset(&serv_addr, '0', sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(PORT);

    // Convert IPv4 and IPv6 addresses from text to binary form
    if(inet_pton(AF_INET, "127.0.0.1", &serv_addr.sin_addr) <= 0) {
        printf("\nInvalid address/ Address not supported \n");
        return -1;
    }
    if (connect(sock, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0) {
        printf("\nConnection Failed \n");
        return -1;
    }
//    send(sock, hello, strlen(hello) , 0);
    send(sock, "grab", strlen("grab") , 0);
    printf("Grab message sent\n");
//    valread = read(sock, buffer, 1024);
    valread = recv(sock, buffer, 1024, NULL);
    buffer[valread] = '\0';                 // null terminate any strings
//    ssize_t    recv(int, void *, size_t, int) __DARWIN_ALIAS_C(recv);
    printf("%s\n", buffer );

    send(sock, "gra", strlen("gra") , 0);
    printf("Gra message sent\n");
    //    valread = read(sock, buffer, 1024);
    valread = recv(sock, buffer, 1024, NULL);
    buffer[valread] = '\0';                 // null terminate any strings
    //    ssize_t    recv(int, void *, size_t, int) __DARWIN_ALIAS_C(recv);
    printf("Received %s\n", buffer );

    send(sock, "exit", strlen("exit") , 0);
    printf("Exit message sent\n");
    //    valread = read(sock, buffer, 1024);
    buffer[valread] = '\0';                 // null terminate any strings
    valread = recv(sock, buffer, 1024, NULL);
    //    ssize_t    recv(int, void *, size_t, int) __DARWIN_ALIAS_C(recv);
    printf("Received %s\n", buffer );

    return 0;
}
