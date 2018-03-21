using System;
using System.IO;
using System.Collections;
using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.UI;

public class NativeBridge : MonoBehaviour
{
    [SerializeField]
    private Toggle toggle;

    private bool skipToggleChangeEvent;
	private bool isSavingScreenshot;
	private string filename;

	public GameObject[] ARObjects;

#if UNITY_IOS && !UNITY_EDITOR
    [DllImport("__Internal")]
	private extern static void UnityFinishedTakingScreenshot();
#else
	private void UnityFinishedTakingScreenshot(){
		Debug.Log( "We don't have anything to handle this :(" );
	}
#endif

    private void AnimateKitten()
    {
        Debug.Log( "-> AnimateKitten()" );
		//resetToActive (GameObject.FindGameObjectsWithTag ("ARObject"));
		foreach (GameObject ARObject in ARObjects)
		{
			ARObject.SetActive(true);
		}
    }

// Todo : need to find the way to get returned screen name from the Swift.
	private String Screenshot(string cmd){
		Debug.Log( "-> Screenshot(): " + cmd );

		ARObjects = GameObject.FindGameObjectsWithTag("ARObject");

        foreach (GameObject ARObject in ARObjects)
        {
            ARObject.SetActive(false);
        }

		filename = "/" + DateTime.Now.ToString("yyyyMMddHHmmss") + "_Screenshot" + ".png";
		//System.IO.File.Delete (Application.persistentDataPath + filename );

		ScreenCapture.CaptureScreenshot(filename);

		isSavingScreenshot = true;
        return filename;
	}

	void Update(){
		if (isSavingScreenshot && System.IO.File.Exists(Application.persistentDataPath + filename )) {
			isSavingScreenshot = false;
			UnityFinishedTakingScreenshot();
		}
	}


//	IEnumerator resetToActive(GameObject[] ARObjects) 
//	{
//		foreach (GameObject ARObject in ARObjects)
//		{
//			ARObject.SetActive(true);
//		}
//	}

//    public void OnToggleValueChanged(bool isOn)
//    {
//        if (!skipToggleChangeEvent)
//        {
//
//            UnityToggleRotation(isOn);
//
//        }
//
////        CubeController.I.ShouldRotate = isOn;
//    }

//    private void AnimateKitten()
//    {
//        switch (command)
//        {
//            case "start":
//                CubeController.I.ShouldRotate = true;
//                break;
//            case "stop":
//                CubeController.I.ShouldRotate = false;
//                break;
//        }
//
//        skipToggleChangeEvent = true;
//        toggle.isOn = CubeController.I.ShouldRotate;
//        skipToggleChangeEvent = false;
//    }

}
