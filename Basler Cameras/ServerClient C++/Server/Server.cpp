// Server side C/C++ program to demonstrate Socket programming
#include <stdio.h>
#include <sys/socket.h>
#include <stdlib.h>
#include <netinet/in.h>
#include <string.h>
// Files for the PYLON API.
#include <pylon/PylonIncludes.h>

#define PORT 8080

using namespace Pylon;
//


int grab(void);

int main(int argc, char const *argv[])
{
    int server_fd, new_socket;
    ssize_t valread;
    struct sockaddr_in address;
    int opt = 1;
    int addrlen = sizeof(address);
    char buffer[1024] = {0};
//    char hello[] = "Hello from server";

    printf("Server starting\n");
   // Creating socket file descriptor
    if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0) {
        perror("socket failed");
        exit(EXIT_FAILURE);
    }

    // Forcefully attaching socket to the port 8080
//    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR | SO_REUSEPORT, &opt, sizeof(opt))) {
//    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEPORT, &opt, sizeof(opt))) {
//        perror("setsockopt");
//        exit(EXIT_FAILURE);
//    }
    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEPORT, &opt, sizeof(opt))) {
        perror("setsockopt");
        exit(EXIT_FAILURE);
    }
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(PORT);

    // Forcefully attaching socket to the port 8080
    if (bind(server_fd, (struct sockaddr *)&address, sizeof(address)) < 0) {
        perror("bind failed");
        exit(EXIT_FAILURE);
    }
    if (listen(server_fd, 3) < 0) {
        perror("listen");
        exit(EXIT_FAILURE);
    }

    // Wait for the client to establish a connection

    if ((new_socket = accept(server_fd, (struct sockaddr *)&address, (socklen_t*)&addrlen)) < 0) {
        perror("accept");
        exit(EXIT_FAILURE);
    }
    printf("Connected to client\n");
    PylonInitialize();
    printf("Pylon initialized\n");
    printf("BaslerServer connected to Client, waiting for message\n");
    for (;;) {
        valread = recv(new_socket, buffer, 1024, NULL);
        if (valread <= 0) {
            continue;
        }
        buffer[valread] = '\0';                 // null terminate any strings
        printf("valread %ld %s\n", valread, buffer);
        if (strcmp(buffer, "grab") == 0) {
            grab();
        }
        else if (strcmp(buffer, "exit") == 0) {
            send(new_socket, buffer, strlen(buffer), 0);
            printf("Exit command received\n");
            break;
        }
        else {
            printf("unrecognized command: %s\n", buffer);
        }
        send(new_socket, buffer, strlen(buffer), 0);
    }
    PylonTerminate();
    return 0;
}

// Grab.cpp
/*
 Note: Before getting started, Basler recommends reading the Programmer's Guide topic
 in the pylon C++ API documentation that gets installed with pylon.
 If you are upgrading to a higher major version of pylon, Basler also
 strongly recommends reading the Migration topic in the pylon C++ API documentation.

 This sample illustrates how to grab and process images using the CInstantCamera class.
 The images are grabbed and processed asynchronously, i.e.,
 while the application is processing a buffer, the acquisition of the next buffer is done
 in parallel.

 The CInstantCamera class uses a pool of buffers to retrieve image data
 from the camera device. Once a buffer is filled and ready,
 the buffer can be retrieved from the camera object for processing. The buffer
 and additional image data are collected in a grab result. The grab result is
 held by a smart pointer after retrieval. The buffer is automatically reused
 when explicitly released or when the smart pointer object is destroyed.
 */


int grab(void)
{
    // Namespace for using cout.
    using namespace std;
    //
    // Number of images to be grabbed.
    static const uint32_t c_countOfImagesToGrab = 100;

   // The exit code of the sample application.
    int exitCode = 0;

    // Before using any pylon methods, the pylon runtime must be initialized.
//    PylonInitialize();

    try
    {
        // Create an instant camera object with the camera device found first.
        CInstantCamera camera( CTlFactory::GetInstance().CreateFirstDevice());

        // Print the model name of the camera.
        cout << "Using device " << camera.GetDeviceInfo().GetModelName() << endl;

        // The parameter MaxNumBuffer can be used to control the count of buffers
        // allocated for grabbing. The default value of this parameter is 10.
        camera.MaxNumBuffer = 5;

        // Start the grabbing of c_countOfImagesToGrab images.
        // The camera device is parameterized with a default configuration which
        // sets up free-running continuous acquisition.
        camera.StartGrabbing( c_countOfImagesToGrab);

        // This smart pointer will receive the grab result data.
        CGrabResultPtr ptrGrabResult;

        // Camera.StopGrabbing() is called automatically by the RetrieveResult() method
        // when c_countOfImagesToGrab images have been retrieved.
        //        while ( camera.IsGrabbing())
        //        {
        // Wait for an image and then retrieve it. A timeout of 5000 ms is used.
        camera.RetrieveResult( 5000, ptrGrabResult, TimeoutHandling_ThrowException);

        // Image grabbed successfully?
        if (ptrGrabResult->GrabSucceeded()) {
            // Access the image data.
            cout << "SizeX: " << ptrGrabResult->GetWidth() << endl;
            cout << "SizeY: " << ptrGrabResult->GetHeight() << endl;
            const uint8_t *pImageBuffer = (uint8_t *) ptrGrabResult->GetBuffer();
//            cout << "Gray value of first pixel: " << (uint32_t) pImageBuffer[0] << endl << endl;
            CImagePersistence::Save(ImageFileFormat_Png, "/Users/maunsell/Desktop/GrabbedImage.png", ptrGrabResult);
            cout << "Saved file\n";
        }
        else
        {
            cout << "Error: " << ptrGrabResult->GetErrorCode() << " " << ptrGrabResult->GetErrorDescription() << endl;
        }
        //        }
    }
    catch (const GenericException &e)
    {
        // Error handling.
        cerr << "An exception occurred." << endl
        << e.GetDescription() << endl;
        exitCode = 1;
    }

    // Releases all pylon resources.
//    PylonTerminate();

    return exitCode;
}
