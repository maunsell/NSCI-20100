//
//  BaslerSocket.m
//  BaslerCamera
//
//  Created by John Maunsell on 2/4/18.
//  Copyright © 2018 John Maunsell. All rights reserved.
//

#import "BaslerSocket.h"

#include <stdio.h>
#include <sys/socket.h>
#include <stdlib.h>
#include <netinet/in.h>
#include <string.h>
#include <arpa/inet.h>
#include <sys/ioctl.h>

#define PORT 8080
#define kBufferLength 1024

@implementation BaslerSocket

- (void)doCommand:(NSString *)command;
{
    ssize_t valread;
    char buffer[kBufferLength] = {0};
    const char *commandStr = [command UTF8String];

    send(theSocket, commandStr, strlen(commandStr) , 0);
    printf("Sent %s\n",commandStr);
    valread = recv(theSocket, buffer, kBufferLength, 0);
    buffer[MIN(valread, kBufferLength - 1)] = '\0';                 // null terminate any strings
    printf("%s\n", buffer);
}

- (BOOL)openSocket
{
    int result;
    //    ssize_t valread;
    struct sockaddr_in serv_addr;
    //    char buffer[1024] = {0};

    if ((theSocket = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        printf("\n Socket creation error \n");
        return NO;
    }
    memset(&serv_addr, '0', sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(PORT);

    // Convert IPv4 and IPv6 addresses from text to binary form
    if (inet_pton(AF_INET, "127.0.0.1", &serv_addr.sin_addr) <= 0) {
        printf("\nInvalid address or address not supported \n");
        return NO;
    }
    if ((result = connect(theSocket, (struct sockaddr *)&serv_addr, sizeof(serv_addr))) < 0) {
        printf("\nConnection Failed with result: %d, %s\n", result, strerror(errno));
        return NO;
    }
    return YES;
}
@end
